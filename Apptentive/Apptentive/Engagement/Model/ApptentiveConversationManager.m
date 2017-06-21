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
#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveLogoutPayload.h"
#import "ApptentiveSDKAppReleasePayload.h"
#import "ApptentiveDevicePayload.h"
#import "ApptentivePersonPayload.h"
#import "ApptentiveConversationRequest.h"
#import "ApptentiveLegacyConversationRequest.h"
#import "ApptentiveLoginRequest.h"
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

@property (strong, nullable, nonatomic) ApptentiveRequestOperation *manifestOperation;
@property (strong, nullable, nonatomic) ApptentiveRequestOperation *loginRequestOperation;

@property (strong, nullable, nonatomic) NSString *pendingLoggedInUserId; // FIXME: get rid off properties

@property (readonly, nonatomic) NSString *metadataPath;
@property (readonly, nonatomic) NSString *manifestPath;

@property (copy, nonatomic) void (^loginCompletionBlock)(BOOL success, NSError *error);

@end


@implementation ApptentiveConversationManager

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
	_activeConversation = [self loadConversation];
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
		legacyConversation.state = ApptentiveConversationStateLegacyPending;
		[self fetchLegacyConversation:legacyConversation];
		[self createMessageManagerForConversation:legacyConversation];
		[Apptentive.shared.backend migrateLegacyCoreDataAndTaskQueueForConversation:legacyConversation];
		return legacyConversation;
	}

	// no conversation available: create a new one
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Can't load conversation: creating anonymous conversation...");
	ApptentiveConversation *anonymousConversation = [[ApptentiveConversation alloc] init];
	anonymousConversation.state = ApptentiveConversationStateAnonymousPending;

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

	if (item.state == ApptentiveConversationStateLoggedIn) {
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
	conversation.state = item.state;
	conversation.encryptionKey = item.encryptionKey;
	conversation.userId = item.userId;
	conversation.token = item.JWT;

	// TODO: check data consistency

	[self createMessageManagerForConversation:conversation];

	return conversation;
}

- (void)createMessageManagerForConversation:(ApptentiveConversation *)conversation {
	NSString *directoryPath = [self conversationContainerPathForDirectoryName:conversation.directoryName];

	_messageManager = [[ApptentiveMessageManager alloc] initWithStoragePath:directoryPath client:self.client pollingInterval:Apptentive.shared.backend.configuration.messageCenter.backgroundPollingInterval conversation:conversation];

	Apptentive.shared.backend.payloadSender.messageDelegate = self.messageManager;
}

- (BOOL)endActiveConversation {
	if (self.activeConversation != nil) {
		ApptentiveLogoutPayload *payload = [[ApptentiveLogoutPayload alloc] initWithToken:self.activeConversation.token];

		[ApptentiveSerialRequest enqueuePayload:payload forConversation:self.activeConversation usingAuthToken:nil inContext:self.parentManagedObjectContext];

		self.activeConversation.state = ApptentiveConversationStateLoggedOut;
		[self.messageManager saveMessageStore];
		_messageManager = nil;

		[self saveConversation];
		[self handleConversationStateChange:self.activeConversation];

		_activeConversation = nil;

		return YES;
	} else {
		ApptentiveLogInfo(@"Attempting to log out, but no conversation is active.");
	}

	return NO;
}

#pragma mark - Conversation Token Fetching

- (void)fetchConversationToken:(ApptentiveConversation *)conversation {
	self.conversationOperation = [self.client requestOperationWithRequest:[[ApptentiveConversationRequest alloc] initWithConversation:conversation] token:nil delegate:self];

	[self.client.operationQueue addOperation:self.conversationOperation];
}

- (BOOL)fetchLegacyConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");
	ApptentiveAssertNil(conversation.token, @"Conversation token already exists");
	ApptentiveAssertTrue(conversation.legacyToken > 0, @"Conversation legacy token is nil or empty");

	if (conversation != nil && conversation.legacyToken.length > 0) {
		self.conversationOperation = [self.client requestOperationWithRequest:[[ApptentiveLegacyConversationRequest alloc] initWithConversation:conversation] legacyToken:conversation.legacyToken delegate:self];

		[self.client.operationQueue addOperation:self.conversationOperation];
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
	if (completion == nil) {
		completion = ^void(BOOL success, NSError *error) {
		};
	}

	self.loginCompletionBlock = [completion copy];

	[self requestLoggedInConversationWithToken:token];
}

- (void)requestLoggedInConversationWithToken:(NSString *)token {
	NSBlockOperation *loginOperation = [NSBlockOperation blockOperationWithBlock:^{
        
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
                ApptentiveLogError(ApptentiveLogTagConversation, @"Unable to find an existing conversation with for user: '%@'", userId);
                [self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"No previous conversations found."];
                return;
            }
            
            ApptentiveAssertNotNil(conversationItem.conversationIdentifier, @"Missing conversation identifier");
            
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

- (void)sendLoginRequestWithToken:(NSString *)token conversationIdentifier:(NSString *)conversationIdentifier userId:(NSString *)userId {
	self.pendingLoggedInUserId = userId;
	self.loginRequestOperation = [self.client requestOperationWithRequest:[[ApptentiveLoginRequest alloc] initWithConversationIdentifier:conversationIdentifier token:token] token:nil delegate:self];

	[self.client.operationQueue addOperation:self.loginRequestOperation];
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
	[self scheduleConversationSave];
}

- (void)conversationAppReleaseOrSDKDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

		ApptentiveSDKAppReleasePayload *payload = [[ApptentiveSDKAppReleasePayload alloc] initWithConversation:self.activeConversation];

		context.parentContext = self.parentManagedObjectContext;

		[context performBlock:^{
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:self.activeConversation usingAuthToken:self.activeConversation.token inContext:context];
		}];

		[self saveConversation];

		self.manifest.expiry = [NSDate distantPast];
	}];

	[self.operationQueue addOperation:conversationDidChangeOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	NSBlockOperation *personDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		context.parentContext = self.parentManagedObjectContext;

		ApptentivePersonPayload *payload = [[ApptentivePersonPayload alloc] initWithPersonDiffs:diffs];

		[context performBlock:^{
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:self.activeConversation usingAuthToken:self.activeConversation.token inContext:context];
		}];

		[self saveConversation];

		[self.delegate processQueuedRecords];
	}];

	[self.operationQueue addOperation:personDidChangeOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	NSBlockOperation *deviceDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		context.parentContext = self.parentManagedObjectContext;

		ApptentiveDevicePayload *payload = [[ApptentiveDevicePayload alloc] initWithDeviceDiffs:diffs];

		[context performBlock:^{
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:self.activeConversation usingAuthToken:self.activeConversation.token inContext:context];
		}];

		[self saveConversation];

		[self.delegate processQueuedRecords];

		self.manifest.expiry = [NSDate distantPast];
	}];

	[self.operationQueue addOperation:deviceDidChangeOperation];
}

- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationSaveOperation = [NSBlockOperation blockOperationWithBlock:^{
		[self saveConversation];
	}];

	[self.operationQueue addOperation:conversationSaveOperation];
}

- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
	NSBlockOperation *conversationSaveOperation = [NSBlockOperation blockOperationWithBlock:^{
		[self saveConversation];
	}];

	[self.operationQueue addOperation:conversationSaveOperation];
}

#pragma mark Apptentive request operation delegate

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	if (operation == self.conversationOperation) {
		if ([operation.request isKindOfClass:[ApptentiveConversationRequest class]]) {
			[self processConversationResponse:(NSDictionary *)operation.responseObject];
		} else if ([operation.request isKindOfClass:[ApptentiveLegacyConversationRequest class]]) {
			[self processLegacyConversationResponse:(NSDictionary *)operation.responseObject];
		} else {
			ApptentiveAssertFail(@"Unexpected request type: %@", NSStringFromClass([operation.request class]));
		}

		self.conversationOperation = nil;
	} else if (operation == self.manifestOperation) {
		[self processManifestResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];

		self.manifestOperation = nil;
	} else if (operation == self.loginRequestOperation) {
		ApptentiveAssertNotNil(self.pendingLoggedInUserId, @"Missing pending user_id");
		[self processLoginResponse:(NSDictionary *)operation.responseObject userId:self.pendingLoggedInUserId];
		self.pendingLoggedInUserId = nil;
		self.loginRequestOperation = nil;
	}
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	if (operation == self.conversationOperation) {
		// This is a permanent failure. We should basically disable the SDK at this point.
		// TODO: disable the SDK until next launch
		self.conversationOperation = nil;

		[self.manifestOperation cancel];
		[self.loginRequestOperation cancel];
	} else if (operation == self.manifestOperation) {
		self.manifestOperation = nil;
	} else if (operation == self.loginRequestOperation) {
		self.loginRequestOperation = nil;
		self.pendingLoggedInUserId = nil;

		[self completeLoginSuccess:NO error:error];
	}
}

- (void)processConversationResponse:(NSDictionary *)conversationResponse {
	[self updateActiveConversationWithResponse:conversationResponse];
}

- (void)processLegacyConversationResponse:(NSDictionary *)conversationResponse {
	[self updateLegacyConversationWithResponse:conversationResponse];
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
	});
}

- (void)processLoginResponse:(NSDictionary *)loginResponse userId:(NSString *)userId {
	NSString *encryptionKey = ApptentiveDictionaryGetString(loginResponse, @"encryption_key");
	if (encryptionKey == nil) {
		[self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Conversation response did not include encryption key."];
		return;
	}

	// if we were previously logged out we might end up with no active conversation
	if (self.activeConversation == nil) {
		ApptentiveConversationMetadataItem *conversationItem = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
            return [item.userId isEqualToString:self.pendingLoggedInUserId];
		}];

		if (conversationItem == nil) {
			[self failLoginWithErrorCode:ApptentiveInternalInconsistency failureReason:@"Unable to find an existing conversation with for user: '%@'", self.pendingLoggedInUserId];
			return;
		}

		_activeConversation = [self loadConversation:conversationItem];
	}

	self.activeConversation.state = ApptentiveConversationStateLoggedIn;
	self.activeConversation.userId = self.pendingLoggedInUserId;
	self.activeConversation.encryptionKey = [NSData apptentive_dataWithHexString:encryptionKey];
	ApptentiveAssertNotNil(self.activeConversation.encryptionKey, @"Apptentive encryption key should be not nil");

	[self saveConversation];
	[self handleConversationStateChange:self.activeConversation];

	[self completeLoginSuccess:YES error:nil];
}

- (BOOL)updateActiveConversationWithResponse:(NSDictionary *)conversationResponse {
	NSString *token = [conversationResponse valueForKey:@"token"];
	NSString *conversationID = [conversationResponse valueForKey:@"id"];
	NSString *personID = [conversationResponse valueForKey:@"person_id"];
	NSString *deviceID = [conversationResponse valueForKey:@"device_id"];

	if (token != nil && conversationID != nil && personID != nil && deviceID != nil) {
		[self.activeConversation setToken:token conversationID:conversationID personID:personID deviceID:deviceID];

		self.messageManager.localUserIdentifier = personID;

		if (self.activeConversation.state == ApptentiveConversationStateAnonymousPending) {
			self.activeConversation.state = ApptentiveConversationStateAnonymous;
		}

		[self saveConversation];

		[self handleConversationStateChange:self.activeConversation];

		return YES;
	} else {
		ApptentiveAssertTrue(NO, @"Conversation response did not include token, conversation identifier, device identifier and/or person identifier.");
		return NO;
	}
}

- (BOOL)updateLegacyConversationWithResponse:(NSDictionary *)conversationResponse {
	ApptentiveAssertNotNil(self.activeConversation, @"Active conversation is nil");
	if (self.activeConversation == nil) {
		return NO;
	}

	ApptentiveAssertTrue(self.activeConversation.state == ApptentiveConversationStateLegacyPending, @"Unexpected conversation state: %@", NSStringFromApptentiveConversationState(self.activeConversation.state));

	NSString *JWT = ApptentiveDictionaryGetString(conversationResponse, @"anonymous_jwt_token");
	NSString *conversationIdentifier = ApptentiveDictionaryGetString(conversationResponse, @"conversation_id");

	if (JWT.length > 0 && conversationIdentifier.length > 0) {
		self.activeConversation.state = ApptentiveConversationStateLegacyPending;
		[self.activeConversation setConversationIdentifier:conversationIdentifier JWT:JWT];

		// TODO: figure out why we need this check
		if (self.activeConversation.state == ApptentiveConversationStateLegacyPending) {
			self.activeConversation.state = ApptentiveConversationStateAnonymous;
		}

		[self saveConversation];
		[self handleConversationStateChange:self.activeConversation];

		return YES;
	}

	ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation response did not include conversation identifier and/or JWT.");
	return NO;
}

- (BOOL)saveConversation {
	ApptentiveStopWatch *saveStopWatch = [[ApptentiveStopWatch alloc] init];

	ApptentiveAssertNotNil(self.activeConversation, @"Missing active conversation");
	if (self.activeConversation == nil) {
		return NO;
	}

	@synchronized(self.activeConversation) {
		NSString *conversationDirectoryPath = [self activeConversationContainerPath];

		BOOL isDirectory = NO;
		if (![[NSFileManager defaultManager] fileExistsAtPath:conversationDirectoryPath isDirectory:&isDirectory] || !isDirectory) {
			NSError *error;

			if (![[NSFileManager defaultManager] createDirectoryAtPath:conversationDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
				ApptentiveAssertTrue(NO, @"Unable to create conversation directory “%@” (%@)", conversationDirectoryPath, error);
				return NO;
			}
		}

		NSString *file = [self conversationArchivePathForDirectoryName:self.activeConversation.directoryName];
		ApptentiveAssertTrue(file.length != 0, @"Conversation file is nil or empty");

		if (file.length == 0) {
			return NO;
		}

		NSData *conversationData = [NSKeyedArchiver archivedDataWithRootObject:self.activeConversation];
		ApptentiveAssertNotNil(conversationData, @"Conversation data serialization failed");

		if (conversationData == nil) {
			return NO;
		}

		if (self.activeConversation.state == ApptentiveConversationStateLoggedIn) {
			ApptentiveStopWatch *encryptionStopWatch = [[ApptentiveStopWatch alloc] init];

			ApptentiveAssertNotNil(self.activeConversation.encryptionKey, @"Missing encryption key");
			if (self.activeConversation.encryptionKey == nil) {
				return NO;
			}

			NSData *initializationVector = [ApptentiveUtilities secureRandomDataOfLength:16];
			ApptentiveAssertTrue(initializationVector.length > 0, @"Unable to generate random initialization vector.");

			if (initializationVector == nil) {
				return NO;
			}

			conversationData = [conversationData apptentive_dataEncryptedWithKey:self.activeConversation.encryptionKey
															initializationVector:initializationVector];
			if (conversationData == nil) {
				ApptentiveLogError(@"Unable to save conversation data: encryption failed");
				return NO;
			}

			ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Conversation data encrypted (took %g ms)", encryptionStopWatch.elapsedMilliseconds);
		}

		BOOL succeed = [conversationData writeToFile:file atomically:YES];
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"Conversation data %@saved (took %g ms): location=%@", succeed ? @"" : @"NOT ", saveStopWatch.elapsedMilliseconds, file);

		return succeed;
	}
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

	self.manifestOperation = [self.client requestOperationWithRequest:[[ApptentiveInteractionsRequest alloc] initWithConversationIdentifier:self.activeConversation.identifier] delegate:self];

	if (!self.activeConversation.token && self.conversationOperation) {
		[self.manifestOperation addDependency:self.conversationOperation];
	}

	[self.client.operationQueue addOperation:self.manifestOperation];
}

- (void)scheduleConversationSave {
	[self.operationQueue addOperationWithBlock:^{
		if (![self saveConversation]) {
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

- (NSString *)activeConversationContainerPath {
	if (self.activeConversation == nil) {
		return nil;
	}

	return [self conversationContainerPathForDirectoryName:self.activeConversation.directoryName];
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
