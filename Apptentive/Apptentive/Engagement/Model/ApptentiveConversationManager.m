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
#import "ApptentiveConversationPayload.h"
#import "ApptentiveDevicePayload.h"
#import "ApptentivePersonPayload.h"
#import "ApptentiveConversationRequest.h"
#import "ApptentiveLoginRequest.h"
#import "ApptentiveInteractionsRequest.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";
static NSString *const ConversationFilename = @"conversation-v1.archive";
static NSString *const ManifestFilename = @"manifest-v1.archive";

static NSInteger ApptentiveInternalInconsistency = -201;
static NSInteger ApptentiveAlreadyLoggedInErrorCode = -202;

NSString *const ApptentiveConversationStateDidChangeNotification = @"ApptentiveConversationStateDidChangeNotification";
NSString *const ApptentiveConversationStateDidChangeNotificationKeyConversation = @"conversation";


@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;

@property (strong, nullable, nonatomic) ApptentiveRequestOperation *manifestOperation;
@property (strong, nullable, nonatomic) ApptentiveRequestOperation *loginRequestOperation;

@property (strong, nullable, nonatomic) ApptentiveConversation *pendingLoggedInConversation;

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
		return item.state == item.state == ApptentiveConversationStateAnonymousPending;
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

	// no conversation available: create a new one
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Can't load conversation: creating anonymous conversation...");
	ApptentiveConversation *anonymousConversation = [[ApptentiveConversation alloc] init];
	anonymousConversation.state = ApptentiveConversationStateAnonymousPending;

	[self fetchConversationToken:anonymousConversation];
	[self createMessageManagerForConversation:anonymousConversation];

	return anonymousConversation;
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)item {
	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithFile:[self conversationArchivePathForDirectoryName:item.directoryName]];
	conversation.state = item.state;

	[self createMessageManagerForConversation:conversation];

	return conversation;
}

- (void)createMessageManagerForConversation:(ApptentiveConversation *)conversation {
	NSString *directoryPath = [self conversationContainerPathForDirectoryName:conversation.directoryName];

	_messageManager = [[ApptentiveMessageManager alloc] initWithStoragePath:directoryPath client:self.client pollingInterval:Apptentive.shared.backend.configuration.messageCenter.backgroundPollingInterval localUserIdentifier:conversation.person.identifier];

	Apptentive.shared.backend.payloadSender.messageDelegate = self.messageManager;
}

- (BOOL)endActiveConversation {
	if (self.activeConversation != nil) {
		self.activeConversation.state = ApptentiveConversationStateLoggedOut;
		[self.messageManager saveMessageStore];
		_messageManager = nil;

		[self saveConversation];
		[self handleConversationStateChange:self.activeConversation];

		ApptentiveLogoutPayload *payload = [[ApptentiveLogoutPayload alloc] initWithConversationIdentifier:self.activeConversation.identifier Token:self.activeConversation.token];

		[ApptentiveSerialRequest enqueuePayload:payload forConversation:self.activeConversation usingAuthToken:Apptentive.shared.APIKey inContext:self.parentManagedObjectContext];

		_activeConversation = nil;

		return YES;
	} else {
		ApptentiveLogInfo(@"Attempting to log out, but no conversation is active.");
	}

	return NO;
}

#pragma mark - Conversation Token Fetching

- (void)fetchConversationToken:(ApptentiveConversation *)conversation {
	self.conversationOperation = [self.client requestOperationWithRequest:[[ApptentiveConversationRequest alloc] initWithConversation:conversation] authToken:Apptentive.shared.APIKey delegate:self];

	[self.client.operationQueue addOperation:self.conversationOperation];
}

- (void)handleConversationStateChange:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation);
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
	if (conversation.state == ApptentiveConversationStateAnonymousPending) {
		ApptentiveLogDebug(@"Skipping updating metadata since conversation is anonymous and pending");
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

	// update the state of the corresponding item
	ApptentiveConversationMetadataItem *item = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
		return [item.conversationIdentifier isEqualToString:conversation.identifier];
	}];
	if (item == nil) {
		item = [[ApptentiveConversationMetadataItem alloc] initWithConversationIdentifier:conversation.identifier directoryName:conversation.directoryName];
		[self.conversationMetadata addItem:item];
	}

	item.state = conversation.state;

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
		if (self.activeConversation == nil) {
			[self sendLoginRequestWithToken:token];
			return;
		}

		switch (self.activeConversation.state) {
			case ApptentiveConversationStateAnonymousPending:
				ApptentiveAssertTrue(NO, @"Login operation should not kick off until conversation fetch complete");
				[self completeLoginSuccess:NO error:[self errorWithCode:ApptentiveInternalInconsistency failureReason:@"Login cannot proceed with Anonymous Pending conversation."]];
				break;

			case ApptentiveConversationStateAnonymous:
				[self sendLoginRequestWithToken:token];
				break;

			case ApptentiveConversationStateLoggedIn:
				[self completeLoginSuccess:NO error:[self errorWithCode:ApptentiveAlreadyLoggedInErrorCode failureReason:@"Unable to log in. A logged in conversation is active."]];
				break;

			default:
				ApptentiveAssertTrue(NO, @"Unexpected conversation state when logging in: %ld", self.activeConversation.state);
				[self completeLoginSuccess:NO error:[self errorWithCode:ApptentiveInternalInconsistency failureReason:@"Unexpected conversation state when logging in."]];
				break;
		}
	}];

	if (self.conversationOperation != nil) {
		[loginOperation addDependency:self.conversationOperation];
	}

	[self.operationQueue addOperation:loginOperation];
}

- (void)sendLoginRequestWithToken:(NSString *)token {
	NSString *path = @"/conversations";
	NSMutableDictionary *payload = [NSMutableDictionary dictionary];

	if (self.activeConversation != nil) {
		ApptentiveAssertTrue(self.activeConversation.state == ApptentiveConversationStateAnonymous, @"Active conversation must be anonymous to log in.");

		if (self.activeConversation.state != ApptentiveConversationStateAnonymous) {
			[self completeLoginSuccess:NO error:[self errorWithCode:ApptentiveInternalInconsistency failureReason:@"Active conversation is not anonymous."]];
			return;
		}

		path = [path stringByAppendingFormat:@"/%@/login", self.activeConversation.identifier];
	} else {
		self.pendingLoggedInConversation = [[ApptentiveConversation alloc] init];
		self.pendingLoggedInConversation.state = ApptentiveConversationStateLoggedIn;

		[payload addEntriesFromDictionary:self.pendingLoggedInConversation.conversationCreationJSON];

		// Add the token to payload…
		payload[@"token"] = token;

		// …and use API key as the authToken
		token = Apptentive.shared.APIKey;
	}

	self.loginRequestOperation = [self.client requestOperationWithRequest:[[ApptentiveLoginRequest alloc] initWithToken:token] authToken:token delegate:self];

	[self.client.operationQueue addOperation:self.loginRequestOperation];
}

- (NSError *)errorWithCode:(NSInteger)code failureReason:(NSString *)failureReason {
	NSDictionary *userInfo = failureReason != nil ? @{NSLocalizedFailureReasonErrorKey: failureReason} : @{};

	return [NSError errorWithDomain:ApptentiveErrorDomain code:code userInfo:userInfo];
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

- (void)conversation:(ApptentiveConversation *)conversation appReleaseOrSDKDidChange:(NSDictionary *)payload {
	NSBlockOperation *conversationDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

		// TODO: sort out which payload exactly we're talking about here
		ApptentiveConversationPayload *payload = [[ApptentiveConversationPayload alloc] initWithConversation:self.activeConversation];

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
		[self processConversationResponse:(NSDictionary *)operation.responseObject];

		self.conversationOperation = nil;
	} else if (operation == self.manifestOperation) {
		[self processManifestResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];

		self.manifestOperation = nil;
	} else if (operation == self.loginRequestOperation) {
		[self processLoginResponse:(NSDictionary *)operation.responseObject];

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
		self.pendingLoggedInConversation = nil;

		[self completeLoginSuccess:NO error:error];
	}
}

- (void)processConversationResponse:(NSDictionary *)conversationResponse {
	[self updateActiveConversationWithResponse:conversationResponse];
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
	});
}

- (void)processLoginResponse:(NSDictionary *)loginResponse {
	if (self.activeConversation == nil && self.pendingLoggedInConversation != nil) {
		_activeConversation = self.pendingLoggedInConversation;
		self.pendingLoggedInConversation = nil;

		if (![self updateActiveConversationWithResponse:loginResponse]) {
			[self completeLoginSuccess:NO error:[self errorWithCode:ApptentiveInternalInconsistency failureReason:@"Conversation response did not include required information."]];
			return;
		}
	}

	[self createMessageManagerForConversation:self.activeConversation];

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

- (BOOL)saveConversation {
	@synchronized(self.activeConversation) {
		NSString *conversationDirectoryPath = [self conversationContainerPathForDirectoryName:self.activeConversation.directoryName];

		BOOL isDirectory = NO;
		if (![[NSFileManager defaultManager] fileExistsAtPath:conversationDirectoryPath isDirectory:&isDirectory] || !isDirectory) {
			NSError *error;

			if (![[NSFileManager defaultManager] createDirectoryAtPath:conversationDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
				ApptentiveAssertTrue(NO, @"Unable to create conversation directory “%@” (%@)", conversationDirectoryPath, error);
				return NO;
			}
		}

		return [NSKeyedArchiver archiveRootObject:self.activeConversation toFile:[self conversationArchivePathForDirectoryName:self.activeConversation.directoryName]];
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

	self.manifestOperation = [self.client requestOperationWithRequest:[[ApptentiveInteractionsRequest alloc] init] delegate:self];

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
