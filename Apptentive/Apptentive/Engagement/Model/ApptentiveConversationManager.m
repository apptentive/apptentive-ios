//
//  ApptentiveConversationManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationManager.h"
#import "ApptentiveConversationMetadata.h"
#import "ApptentiveConversationMetadataItem.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveEngagementManifest.h"
#import "Apptentive_Private.h"
#import "ApptentiveClient.h"
#import "ApptentiveBackend.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveLogoutPayload.h"
#import "ApptentiveSDKAppReleasePayload.h"
#import "ApptentiveDevicePayload.h"
#import "ApptentivePersonPayload.h"
#import "ApptentiveConversationRequest.h"
#import "ApptentiveLegacyConversationRequest.h"
#import "ApptentiveNewLoginRequest.h"
#import "ApptentiveExistingLoginRequest.h"
#import "ApptentiveInteractionsRequest.h"
#import "ApptentiveSafeCollections.h"
#import "NSData+Encryption.h"
#import "ApptentiveJWT.h"
#import "ApptentiveStopWatch.h"
#import "ApptentiveSafeCollections.h"


static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";
static NSString *const ConversationFilename = @"conversation-v1.archive";
static NSString *const ManifestFilename = @"manifest-v1.archive";

static NSInteger ApptentiveInternalInconsistency = -201;
static NSInteger ApptentiveAlreadyLoggedInErrorCode = -202;

NSString *const ApptentiveConversationStateDidChangeNotification = @"ApptentiveConversationStateDidChangeNotification";
NSString *const ApptentiveConversationStateDidChangeNotificationKeyConversation = @"conversation";


@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nullable, nonatomic) ApptentiveConversation *activeConversation;
@property (strong, nullable, nonatomic) ApptentiveRequestOperation *manifestOperation;
@property (strong, nullable, nonatomic) ApptentiveRequestOperation *loginRequestOperation;

@property (readonly, nonatomic) NSString *metadataPath;
@property (readonly, nonatomic) NSString *manifestPath;

@property (copy, nonatomic) void (^loginCompletionBlock)(BOOL success, NSError *error);

@end


@implementation ApptentiveConversationManager

@synthesize activeConversation = _activeConversation;

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue client:(ApptentiveClient *)client parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_operationQueue = operationQueue;
		_client = client;
		_parentManagedObjectContext = parentManagedObjectContext;
	}

	return self;
}

#pragma mark - Conversations

/**
 Attempts to load a logged-in conversation. If no conversations are found, a new one will be created.
 If only logged-out conversations are found, returns `NO`.

 @return `YES` if a conversation was loaded
 */
- (BOOL)loadActiveConversation {
	// resolving metadata
	_conversationMetadata = [self resolveMetadata];

	// attempt to load existing conversation
	self.activeConversation = [self loadConversation];
	// TODO: dispatch debug event (EVT_CONVERSATION_LOAD_ACTIVE, activeConversation != null);

	if (self.activeConversation != nil) {
		self.activeConversation.delegate = self;

		[self handleConversationStateChange:self.activeConversation];
		return true;
	}

	return false;
}

- (ApptentiveConversation *)loadConversation {
	// we're going to scan metadata in attempt to find existing conversations
	ApptentiveConversationMetadataItem *item;

	// if the user was logged in previously - we should have an active conversation
	item = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.state == ApptentiveConversationStateLoggedIn;
	}];
	if (item != nil) {
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"Loading logged-in conversation...");
		return [self loadConversation:item];
	}

	// if no users were logged in previously - we might have an anonymous conversation
	item = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
		return item.state == ApptentiveConversationStateAnonymous;
	}];

	if (item != nil) {
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"Loading anonymous conversation...");
		return [self loadConversation:item];
	}

	// check if we have a 'pending' anonymous conversation
	item = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
		return item.state == ApptentiveConversationStateAnonymousPending;
	}];
	if (item != nil) {
		ApptentiveConversation *conversation = [self loadConversation:item];
		[self fetchConversationToken:conversation];
		return conversation;
	}

	// any remaining conversations are 'logged out', and we should not load them.
	if (self.conversationMetadata.items.count > 0) {
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"Can't load conversation: only 'logged-out' conversations available");
		return nil;
	}

	// attempt to load a legacy conversation
	ApptentiveConversation *legacyConversation = [[ApptentiveConversation alloc] initAndMigrate];
	if (legacyConversation != nil) {
		[self fetchLegacyConversation:legacyConversation];
		[self createMessageManagerForConversation:legacyConversation];
		[Apptentive.shared.backend migrateLegacyCoreDataAndTaskQueueForConversation:legacyConversation];

		[self migrateEngagementManifest];

		return legacyConversation;
	}

	// no conversation available: create a new one
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Can't load conversation: creating anonymous conversation...");
	ApptentiveConversation *anonymousConversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymousPending];
	[self fetchConversationToken:anonymousConversation];
	[self createMessageManagerForConversation:anonymousConversation];

	return anonymousConversation;
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)item {
	ApptentiveAssertNotNil(item, @"Conversation metadata item is nil");
	if (item == nil) {
		return nil;
	}

	NSString *file = [self conversationArchivePathForDirectoryName:item.directoryName];
	ApptentiveAssertNotNil(file, @"Conversation data file is nil: %@", item.directoryName);
	if (file == nil) {
		return nil;
	}

	NSData *conversationData = [[NSData alloc] initWithContentsOfFile:file];
	ApptentiveAssertNotNil(conversationData, @"Conversation data is nil: %@", file);
	if (conversationData == nil) {
		return nil;
	}

	// Decrypt any non-anonymous conversation that we're trying to load
	// A logged-out conversation may not be logged in just yet
	if (item.state == ApptentiveConversationStateLoggedIn || item.state == ApptentiveConversationStateLoggedOut) {
		ApptentiveStopWatch *decryptionStopWatch = [ApptentiveStopWatch new];

		ApptentiveAssertNotNil(item.encryptionKey, @"Missing encryption key");
		if (item.encryptionKey == nil) {
			return nil;
		}

		conversationData = [conversationData apptentive_dataDecryptedWithKey:item.encryptionKey];
		ApptentiveAssertNotNil(item.encryptionKey, @"Can't decrypt conversation data");
		if (conversationData == nil) {
			return nil;
		}

		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Conversation decrypted (took %g ms)", decryptionStopWatch.elapsedMilliseconds);
	}

	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithData:conversationData];
	ApptentiveAssertNotNil(conversation, @"Failed to load conversation");
	if (conversation == nil) {
		return nil;
	}

	// TODO: do we need a mutable conversation here or can we just load it from the archive
	ApptentiveMutableConversation *mutableConversation = [conversation mutableCopy];

	mutableConversation.state = item.state;
	mutableConversation.encryptionKey = item.encryptionKey;
	mutableConversation.userId = item.userId;
	mutableConversation.token = item.JWT;

	// TODO: check data consistency

	[self createMessageManagerForConversation:mutableConversation];

	return mutableConversation;
}

- (void)createMessageManagerForConversation:(ApptentiveConversation *)conversation {
	NSString *directoryPath = [self conversationContainerPathForDirectoryName:conversation.directoryName];

	_messageManager = [[ApptentiveMessageManager alloc] initWithStoragePath:directoryPath client:self.client pollingInterval:Apptentive.shared.backend.configuration.messageCenter.backgroundPollingInterval conversation:conversation operationQueue:self.operationQueue];

	Apptentive.shared.backend.payloadSender.messageDelegate = self.messageManager;
}

- (void)endActiveConversation {
	ApptentiveAssertOperationQueue(self.operationQueue);

	if (self.activeConversation != nil) {
		ApptentiveMutableConversation *conversation = [self.activeConversation mutableCopy];

		ApptentiveLogoutPayload *payload = [[ApptentiveLogoutPayload alloc] init];

		[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.parentManagedObjectContext];

		[Apptentive.shared.backend processQueuedRecords];

		conversation.state = ApptentiveConversationStateLoggedOut;
		[self.messageManager saveMessageStore];
		_messageManager = nil;

		[self saveConversation:conversation];
		[self handleConversationStateChange:conversation];

		self.activeConversation = nil;
	} else {
		ApptentiveLogInfo(@"Attempting to log out, but no conversation is active.");
	}
}

#pragma mark - Conversation Token Fetching

- (void)fetchConversationToken:(ApptentiveConversation *)conversation {
	ApptentiveRequestOperationCallback *delegate = [ApptentiveRequestOperationCallback new];
	delegate.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
        [self conversation:conversation processFetchResponse:(NSDictionary *)operation.responseObject];
        self.conversationOperation = nil;
	};
	delegate.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
        self.conversationOperation = nil;
        [self conversation:conversation processFetchResponseError:error];
	};

	self.conversationOperation = [self.client requestOperationWithRequest:[[ApptentiveConversationRequest alloc] initWithConversation:conversation] token:nil delegate:delegate];

	[self.client.networkQueue addOperation:self.conversationOperation];
}

- (BOOL)fetchLegacyConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");
	ApptentiveAssertNil(conversation.token, @"Conversation token already exists");
	ApptentiveAssertTrue(conversation.legacyToken > 0, @"Conversation legacy token is nil or empty");

	ApptentiveRequestOperationCallback *delegate = [ApptentiveRequestOperationCallback new];
	delegate.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
        [self legacyConversation:conversation processFetchResponse:(NSDictionary *)operation.responseObject];
        self.conversationOperation = nil;
	};
	delegate.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
        // This is a permanent failure. We should basically disable the SDK at this point.
        // TODO: disable the SDK until next launch
        self.conversationOperation = nil;
        [self conversation:conversation processFetchResponseError:error];
	};

	if (conversation != nil && conversation.legacyToken.length > 0) {
		self.conversationOperation = [self.client requestOperationWithRequest:[[ApptentiveLegacyConversationRequest alloc] initWithConversation:conversation] legacyToken:conversation.legacyToken delegate:delegate];

		[self.client.networkQueue addOperation:self.conversationOperation];
		return YES;
	}

	return NO;
}

- (void)handleConversationStateChange:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");
	if (conversation != nil) {
		NSDictionary *userInfo = @{ApptentiveConversationStateDidChangeNotificationKeyConversation: conversation};
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveConversationStateDidChangeNotification
															object:self
														  userInfo:userInfo];

		if ([self.delegate respondsToSelector:@selector(conversationManager:conversationDidChangeState:)]) {
			[self.delegate conversationManager:self conversationDidChangeState:conversation];
		}
	}

	[self updateMetadataItems:conversation];
}

- (void)updateMetadataItems:(ApptentiveConversation *)conversation {
	if (conversation.state == ApptentiveConversationStateAnonymousPending ||
		conversation.state == ApptentiveConversationStateLegacyPending) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Skipping updating metadata since conversation is %@", NSStringFromApptentiveConversationState(conversation.state));
		return;
	}

	// if the conversation is 'logged-in' we should not have any other 'logged-in' items in metadata
	if (conversation.state == ApptentiveConversationStateLoggedIn) {
		for (ApptentiveConversationMetadataItem *item in self.conversationMetadata.items) {
			if (item.state == ApptentiveConversationStateLoggedIn) {
				item.state = ApptentiveConversationStateLoggedOut;
			}
		}
	}

	// delete all existing encryption keys
	for (ApptentiveConversationMetadataItem *item in self.conversationMetadata.items) {
		item.encryptionKey = nil;
	}

	// update the state of the corresponding item
	ApptentiveConversationMetadataItem *item = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
		return [item.conversationIdentifier isEqualToString:conversation.identifier];
	}];
	if (item == nil) {
		item = [[ApptentiveConversationMetadataItem alloc] initWithConversationIdentifier:conversation.identifier directoryName:conversation.directoryName];
		[self.conversationMetadata addItem:item];
	}

	item.state = conversation.state;
	item.JWT = conversation.token; // TODO: check nil for 'active' conversations

	if (item.state == ApptentiveConversationStateLoggedIn) {
		ApptentiveAssertNotNil(conversation.encryptionKey, @"Encryption key is nil");
		item.encryptionKey = conversation.encryptionKey;
		ApptentiveAssertNotNil(conversation.userId, @"User id is nil");
		item.userId = conversation.userId;
	}

	[self saveMetadata];
}

#pragma mark - Metadata

- (ApptentiveConversationMetadata *)resolveMetadata {
	NSString *metadataPath = self.metadataPath;

	ApptentiveConversationMetadata *metadata = nil;
	if ([ApptentiveUtilities fileExistsAtPath:metadataPath]) {
		metadata = [NSKeyedUnarchiver unarchiveObjectWithFile:metadataPath];
		if (metadata) {
			// TODO: dispatch debug event
			return metadata;
		}

		ApptentiveLogWarning(@"Unable to deserialize metadata from file: %@", metadataPath);
	}

	return [[ApptentiveConversationMetadata alloc] init];
}

- (BOOL)saveMetadata {
	return [NSKeyedArchiver archiveRootObject:self.conversationMetadata toFile:self.metadataPath];
}

#pragma mark - Login/Logout

- (void)logInWithToken:(NSString *)token completion:(void (^)(BOOL, NSError *_Nonnull))completion {
	ApptentiveAssertOperationQueue(self.operationQueue);

	self.loginCompletionBlock = [completion copy];

	[self requestLoggedInConversationWithToken:token];
}

- (void)requestLoggedInConversationWithToken:(NSString *)token {
	NSBlockOperation *loginOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        ApptentiveAssertOperationQueue(self.operationQueue);
        
        NSError *jwtError;
        ApptentiveJWT *jwt = [ApptentiveJWT JWTWithContentOfString:token error:&jwtError];
        if (jwtError != nil) {
            [self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"JWT parsing error: %@", jwtError];
            return;
        }
        
        NSString *userId = jwt.payload[@"sub"];
        if (userId.length == 0) {
            [self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"'user_id' is nil or empty."];
            return;
        }

        // Check if there is an active conversation
		if (self.activeConversation == nil) {
            ApptentiveLogDebug(ApptentiveLogTagConversation, @"No active conversation. Performing login...");
            
            // attempt to find previous logged out conversation
            ApptentiveConversationMetadataItem *conversationItem = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
                return [item.userId isEqualToString:userId];
            }];
            
            if (conversationItem == nil) {
                ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Logging in a new user...");
                [self sendLoginRequestWithToken:token conversationIdentifier:nil userId:userId];
                return;
            }
            
            ApptentiveAssertNotNil(conversationItem.conversationIdentifier, @"Missing conversation identifier");
            
            ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Logging in an existing user (%@)...", userId);
            [self sendLoginRequestWithToken:token conversationIdentifier:conversationItem.conversationIdentifier userId:userId];
			return;
		}

		switch (self.activeConversation.state) {
			case ApptentiveConversationStateAnonymousPending:
            case ApptentiveConversationStateLegacyPending:
				ApptentiveAssertTrue(NO, @"Login operation should not kick off until conversation fetch complete");
                [self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Login cannot proceed with Anonymous Pending conversation."];
				break;

			case ApptentiveConversationStateAnonymous:
				[self sendLoginRequestWithToken:token conversationIdentifier:self.activeConversation.identifier userId:userId];
				break;

			case ApptentiveConversationStateLoggedIn:
                [self failLoginWithErrorCode:ApptentiveAlreadyLoggedInErrorCode failureReason:@"A logged in conversation is active."];
				break;

			default:
				ApptentiveAssertTrue(NO, @"Unexpected conversation state when logging in: %@", NSStringFromApptentiveConversationState(self.activeConversation.state));
                [self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Unexpected conversation state when logging in: %@", NSStringFromApptentiveConversationState(self.activeConversation.state)];
				break;
		}
	}];

	if (self.conversationOperation != nil) {
		[loginOperation addDependency:self.conversationOperation];
	}

	[self.operationQueue addOperation:loginOperation];
}

- (void)sendLoginRequestWithToken:(NSString *)token conversationIdentifier:(nullable NSString *)conversationIdentifier userId:(NSString *)userId {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveAssertNotEmpty(token, @"Attempted to send login request with nil or empty conversation token");
	ApptentiveAssertNotEmpty(userId, @"Attempted to send login request with nil or empty user id");

	ApptentiveRequestOperationCallback *delegate = [ApptentiveRequestOperationCallback new];
	delegate.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
        [self conversation:self.activeConversation processLoginResponse:(NSDictionary *)operation.responseObject userId:userId token:token];
        self.loginRequestOperation = nil;
	};
	delegate.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
        self.loginRequestOperation = nil;
        [self completeLoginSuccess:NO error:error];
	};

	id<ApptentiveRequest> request = conversationIdentifier != nil ?
		[[ApptentiveExistingLoginRequest alloc] initWithConversationIdentifier:conversationIdentifier token:token] :
		[[ApptentiveNewLoginRequest alloc] initWithToken:token];
	self.loginRequestOperation = [self.client requestOperationWithRequest:request token:nil delegate:delegate];

	[self.client.networkQueue addOperation:self.loginRequestOperation];
}

- (NSError *)errorWithCode:(NSInteger)code failureReason:(NSString *)failureReason {
	NSDictionary *userInfo = failureReason != nil ? @{NSLocalizedFailureReasonErrorKey: failureReason} : @{};

	return [NSError errorWithDomain:ApptentiveErrorDomain code:code userInfo:userInfo];
}

- (void)failLoginWithErrorCode:(NSInteger)errorCode failureReason:(NSString *)format, ... {
	va_list ap;
	va_start(ap, format);
	NSString *failureReason = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);

	NSError *error = [self errorWithCode:errorCode failureReason:failureReason];
	[self completeLoginSuccess:NO error:error];
}

- (void)completeLoginSuccess:(BOOL)success error:(NSError *)error {
	self.loginCompletionBlock(success, error);
	self.loginCompletionBlock = nil;
}

#pragma mark - ApptentiveConversationDelegate

/**
 Indicates that the conversation object (any of its parts) has changed.
 
 @param conversation The conversation associated with the change.
 server.
 */
- (void)conversationDidChange:(ApptentiveConversation *)conversation {
	[self scheduleSaveConversation:conversation];
}

- (void)conversationAppReleaseOrSDKDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		ApptentiveSDKAppReleasePayload *payload = [[ApptentiveSDKAppReleasePayload alloc] initWithConversation:conversation];

        [ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.parentManagedObjectContext];

        [self saveConversation:conversation];

		self.manifest.expiry = [NSDate distantPast];
	}];

	[self.operationQueue addOperation:conversationDidChangeOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	NSBlockOperation *personDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		ApptentivePersonPayload *payload = [[ApptentivePersonPayload alloc] initWithPersonDiffs:diffs];

        [ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.parentManagedObjectContext];

        [self saveConversation:conversation];

		[self.delegate processQueuedRecords];
	}];

	[self.operationQueue addOperation:personDidChangeOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	NSBlockOperation *deviceDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		ApptentiveDevicePayload *payload = [[ApptentiveDevicePayload alloc] initWithDeviceDiffs:diffs];

		[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:self.parentManagedObjectContext];
        
		[self saveConversation:conversation];

		[self.delegate processQueuedRecords];

		self.manifest.expiry = [NSDate distantPast];
	}];

	[self.operationQueue addOperation:deviceDidChangeOperation];
}

- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationSaveOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self saveConversation:conversation];
	}];

	[self.operationQueue addOperation:conversationSaveOperation];
}

- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationSaveOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self saveConversation:conversation];
	}];

	[self.operationQueue addOperation:conversationSaveOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation processFetchResponse:(NSDictionary *)conversationResponse {
	[self updateActiveConversation:conversation withResponse:conversationResponse];
}

- (void)legacyConversation:(ApptentiveConversation *)conversation processFetchResponse:(NSDictionary *)conversationResponse {
	[self updateLegacyConversation:conversation withResponse:conversationResponse];
}

- (void)conversation:(ApptentiveConversation *)conversation processFetchResponseError:(NSError *)error {
	// This is a permanent failure. We should basically disable the SDK at this point.
	// TODO: disable the SDK until next launch

	[self.manifestOperation cancel];
	[self.loginRequestOperation cancel];
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
	});
}

- (void)conversation:(ApptentiveConversation *)conversation processLoginResponse:(NSDictionary *)loginResponse userId:(NSString *)userId token:(NSString *)token {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveAssertNotEmpty(token, @"Empty token in login request");

	NSString *encryptionKey = ApptentiveDictionaryGetString(loginResponse, @"encryption_key");
	NSString *deviceIdentifier = ApptentiveDictionaryGetString(loginResponse, @"device_id");
	NSString *personIdentifier = ApptentiveDictionaryGetString(loginResponse, @"person_id");

	if (encryptionKey == nil) {
		[self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Login response did not include encryption key."];
		return;
	}

	NSString *conversationIdentifier = ApptentiveDictionaryGetString(loginResponse, @"id");
	if (conversationIdentifier == nil) {
		[self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Login response did not include conversation identifier."];
		return;
	}

	// if we were previously logged out we might end up with no active conversation
	ApptentiveMutableConversation *mutableConversation;
	if (conversation == nil) {
		ApptentiveConversationMetadataItem *conversationItem = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
            return [item.userId isEqualToString:userId];
		}];

		if (conversationItem == nil) {
			ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Can't load conversation for user '%@': creating a new one...", userId);
			ApptentiveConversation *newConversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];
			[self createMessageManagerForConversation:newConversation];
			mutableConversation = [newConversation mutableCopy];
		} else if ([conversationItem.conversationIdentifier isEqualToString:conversationIdentifier]) {
			ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Loading conversation for user '%@'...", userId);
			conversationItem.encryptionKey = [NSData apptentive_dataWithHexString:encryptionKey];
			ApptentiveConversation *existingConversation = [self loadConversation:conversationItem];
			mutableConversation = [existingConversation mutableCopy];
		} else {
			[self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Mismatching conversation identifiers for user '%@'. Expected '%@' but was '%@'", userId, conversationItem.conversationIdentifier, conversationIdentifier];
			return;
		}
	} else {
		mutableConversation = [conversation mutableCopy];
	}

	[mutableConversation setToken:token conversationID:conversationIdentifier personID:personIdentifier deviceID:deviceIdentifier];
	mutableConversation.state = ApptentiveConversationStateLoggedIn;
	mutableConversation.userId = userId;
	mutableConversation.encryptionKey = [NSData apptentive_dataWithHexString:encryptionKey];
	ApptentiveAssertNotNil(mutableConversation.encryptionKey, @"Apptentive encryption key should be not nil");

	self.activeConversation = mutableConversation;

	[self saveConversation:mutableConversation];
	[self handleConversationStateChange:mutableConversation];

	[self completeLoginSuccess:YES error:nil];
}

- (BOOL)updateActiveConversation:(ApptentiveConversation *)conversation withResponse:(NSDictionary *)conversationResponse {
	ApptentiveAssertOperationQueue(self.operationQueue);

	NSString *token = [conversationResponse valueForKey:@"token"];
	NSString *conversationID = [conversationResponse valueForKey:@"id"];
	NSString *personID = [conversationResponse valueForKey:@"person_id"];
	NSString *deviceID = [conversationResponse valueForKey:@"device_id"];

	if (token != nil && conversationID != nil && personID != nil && deviceID != nil) {
		ApptentiveMutableConversation *mutableConversation = [conversation mutableCopy];

		[mutableConversation setToken:token conversationID:conversationID personID:personID deviceID:deviceID];

		self.messageManager.localUserIdentifier = personID;

		if (mutableConversation.state == ApptentiveConversationStateAnonymousPending) {
			mutableConversation.state = ApptentiveConversationStateAnonymous;
		}

		self.activeConversation = mutableConversation;

		[self saveConversation:self.activeConversation];

		[self handleConversationStateChange:self.activeConversation];

		return YES;
	} else {
		ApptentiveAssertTrue(NO, @"Conversation response did not include token, conversation identifier, device identifier and/or person identifier.");
		return NO;
	}
}

- (BOOL)updateLegacyConversation:(ApptentiveConversation *)conversation withResponse:(NSDictionary *)conversationResponse {
	ApptentiveAssertNotNil(conversation, @"Active conversation is nil");
	if (conversation == nil) {
		return NO;
	}

	ApptentiveAssertTrue(conversation.state == ApptentiveConversationStateLegacyPending, @"Unexpected conversation state: %@", NSStringFromApptentiveConversationState(conversation.state));

	NSString *JWT = ApptentiveDictionaryGetString(conversationResponse, @"anonymous_jwt_token");
	NSString *conversationIdentifier = ApptentiveDictionaryGetString(conversationResponse, @"conversation_id");

	if (JWT.length > 0 && conversationIdentifier.length > 0) {
		ApptentiveMutableConversation *mutableConversation = [conversation mutableCopy];

		mutableConversation.state = ApptentiveConversationStateLegacyPending;
		[mutableConversation setConversationIdentifier:conversationIdentifier JWT:JWT];

		// TODO: figure out why we need this check
		if (mutableConversation.state == ApptentiveConversationStateLegacyPending) {
			mutableConversation.state = ApptentiveConversationStateAnonymous;
		}

		self.activeConversation = mutableConversation;

		[self saveConversation:self.activeConversation];
		[self handleConversationStateChange:self.activeConversation];

		return YES;
	}

	ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation response did not include conversation identifier and/or JWT.");
	return NO;
}

- (BOOL)saveConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation, @"Attempted to save nil conversation");
	if (conversation == nil) {
		return NO;
	}

	ApptentiveStopWatch *saveStopWatch = [[ApptentiveStopWatch alloc] init];

	NSString *conversationDirectoryPath = [self conversationContainerPathForDirectoryName:conversation.directoryName];

	BOOL isDirectory = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:conversationDirectoryPath isDirectory:&isDirectory] || !isDirectory) {
		NSError *error;

		if (![[NSFileManager defaultManager] createDirectoryAtPath:conversationDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveAssertTrue(NO, @"Unable to create conversation directory “%@” (%@)", conversationDirectoryPath, error);
			return NO;
		}
	}

	NSString *file = [self conversationArchivePathForDirectoryName:conversation.directoryName];
	ApptentiveAssertTrue(file.length != 0, @"Conversation file is nil or empty");

	if (file.length == 0) {
		return NO;
	}

	NSData *conversationData;
	@synchronized(conversation) {
		conversationData = [NSKeyedArchiver archivedDataWithRootObject:conversation];
	}

	ApptentiveAssertNotNil(conversationData, @"Conversation data serialization failed");

	if (conversationData == nil) {
		return NO;
	}

	// All non-anonymous conversations should be encrypted
	// We may have just logged out, so also encrypt logged-out conversations
	if (conversation.state == ApptentiveConversationStateLoggedIn || conversation.state == ApptentiveConversationStateLoggedOut) {
		ApptentiveStopWatch *encryptionStopWatch = [[ApptentiveStopWatch alloc] init];

		ApptentiveAssertNotNil(conversation.encryptionKey, @"Missing encryption key");
		if (conversation.encryptionKey == nil) {
			return NO;
		}

		NSData *initializationVector = [ApptentiveUtilities secureRandomDataOfLength:16];
		ApptentiveAssertTrue(initializationVector.length > 0, @"Unable to generate random initialization vector.");

		if (initializationVector == nil) {
			return NO;
		}

		conversationData = [conversationData apptentive_dataEncryptedWithKey:conversation.encryptionKey
														initializationVector:initializationVector];
		if (conversationData == nil) {
			ApptentiveLogError(@"Unable to save conversation data: encryption failed");
			return NO;
		}

		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Conversation data encrypted (took %g ms)", encryptionStopWatch.elapsedMilliseconds);
	} else {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Saving unencrypted conversation data");
	}

	BOOL succeed = [conversationData writeToFile:file atomically:YES];
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Conversation data %@saved (took %g ms): location=%@", succeed ? @"" : @"NOT ", saveStopWatch.elapsedMilliseconds, file);

	return succeed;
}

- (BOOL)saveManifest {
	@synchronized(self.manifest) {
		return [NSKeyedArchiver archiveRootObject:_manifest toFile:[self manifestPath]];
	}
}

#pragma mark - Private

- (void)fetchEngagementManifest {
	if (self.manifestOperation != nil) {
		return;
	}

	ApptentiveRequestOperationCallback *callback = [ApptentiveRequestOperationCallback new];
	callback.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
        [self processManifestResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];
        self.manifestOperation = nil;
	};
	callback.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
        self.manifestOperation = nil;
	};

	self.manifestOperation = [self.client requestOperationWithRequest:[[ApptentiveInteractionsRequest alloc] initWithConversationIdentifier:self.activeConversation.identifier] delegate:callback];

	if (!self.activeConversation.token && self.conversationOperation) {
		[self.manifestOperation addDependency:self.conversationOperation];
	}

	[self.client.networkQueue addOperation:self.manifestOperation];
}

- (void)migrateEngagementManifest {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithCachePath:self.storagePath userDefaults:[NSUserDefaults standardUserDefaults]];

	if (self.manifest) {
		[ApptentiveEngagementManifest deleteMigratedDataFromCachePath:self.storagePath];
	}
}

- (void)scheduleSaveConversation:(ApptentiveConversation *)conversation {
	[self.operationQueue addOperationWithBlock:^{
        if (![self saveConversation:conversation]) {
			ApptentiveLogError(@"Error saving active conversation.");
		}
	}];
}

#pragma mark - Paths

- (NSString *)metadataPath {
	return [self.storagePath stringByAppendingPathComponent:ConversationMetadataFilename];
}

- (NSString *)manifestPath {
	return [self.storagePath stringByAppendingPathComponent:ManifestFilename];
}

- (NSString *)conversationArchivePathForDirectoryName:(NSString *)directoryName {
	return [[self conversationContainerPathForDirectoryName:directoryName] stringByAppendingPathComponent:ConversationFilename];
}

- (NSString *)conversationContainerPathForDirectoryName:(NSString *)directoryName {
	return [self.storagePath stringByAppendingPathComponent:directoryName];
}

#pragma mark - Metadata

- (void)resume {
#if APPTENTIVE_DEBUG
	[Apptentive.shared checkSDKConfiguration];

	self.manifest.expiry = [NSDate distantPast];
#endif

	if ([self.manifest.expiry timeIntervalSinceNow] <= 0) {
		[self fetchEngagementManifest];
	}

	[self.messageManager checkForMessages];
}

- (void)pause {
	[self saveMetadata];
}

- (ApptentiveConversation *)activeConversationTemp {
	return _activeConversation;
}

- (ApptentiveConversation *)activeConversation {
	ApptentiveAssertOperationQueue(self.operationQueue);
	return _activeConversation;
}

- (void)setActiveConversation:(ApptentiveConversation *)activeConversation {
	ApptentiveAssertOperationQueue(self.operationQueue);
	_activeConversation = activeConversation;
}


#pragma mark - Debugging

- (void)setLocalEngagementManifestURL:(NSURL *)localEngagementManifestURL {
	if (_localEngagementManifestURL != localEngagementManifestURL) {
		_localEngagementManifestURL = localEngagementManifestURL;

		if (localEngagementManifestURL == nil) {
			_manifest = [NSKeyedUnarchiver unarchiveObjectWithFile:[self manifestPath]];

			if ([self.manifest.expiry timeIntervalSinceNow] <= 0) {
				[self fetchEngagementManifest];
			}
		} else {
			[self.manifestOperation cancel];

			NSError *error;
			NSData *localData = [NSData dataWithContentsOfURL:localEngagementManifestURL];
			NSDictionary *manifestDictionary = [NSJSONSerialization JSONObjectWithData:localData options:0 error:&error];

			if (!manifestDictionary) {
				ApptentiveLogError(@"Unable to parse local manifest %@: %@", localEngagementManifestURL.absoluteString, error);
			}

			_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestDictionary cacheLifetime:MAXFLOAT];

			[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
		}
	}
}

@end
