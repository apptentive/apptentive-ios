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
#import "ApptentiveNetworkQueue.h"
#import "ApptentiveBackend.h"
#import "ApptentivePerson.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveAppConfiguration.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";
static NSString *const ConversationFilename = @"conversation-v1.archive";
static NSString *const ManifestFilename = @"manifest-v1.archive";

NSString *const ApptentiveConversationStateDidChangeNotification = @"ApptentiveConversationStateDidChangeNotification";
NSString *const ApptentiveConversationStateDidChangeNotificationKeyConversation = @"conversation";


@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;

@property (strong, nonatomic, nullable) ApptentiveRequestOperation *manifestOperation;

@property (readonly, nonatomic) NSString *metadataPath;
@property (readonly, nonatomic) NSString *manifestPath;

@end


@implementation ApptentiveConversationManager

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue networkQueue:(nonnull ApptentiveNetworkQueue *)networkQueue parentManagedObjectContext:(nonnull NSManagedObjectContext *)parentManagedObjectContext {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_operationQueue = operationQueue;
		_networkQueue = networkQueue;
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
	anonymousConversation.directoryName = [NSUUID UUID].UUIDString;

	[self fetchConversationToken:anonymousConversation];
	[self createMessageManagerForConversation:anonymousConversation];

	return anonymousConversation;
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)item {
	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithFile:[self conversationArchivePathForDirectoryName:item.directoryName]];
	conversation.state = item.state;
	conversation.directoryName = item.directoryName;

	[self createMessageManagerForConversation:conversation];

	return conversation;
}

- (void)createMessageManagerForConversation:(ApptentiveConversation *)conversation {
	NSString *directoryPath = [self conversationContainerPathForDirectoryName:conversation.directoryName];

	_messageManager = [[ApptentiveMessageManager alloc] initWithStoragePath:directoryPath networkQueue:self.networkQueue pollingInterval:Apptentive.shared.backend.configuration.messageCenter.backgroundPollingInterval localUserIdentifier:conversation.person.identifier];
}

- (BOOL)endActiveConversation {
	if (self.activeConversation != nil) {
		self.activeConversation.state = ApptentiveConversationStateLoggedOut;
		[self.messageManager saveMessageStore];
		_messageManager = nil;

		[self saveConversation];
		[self handleConversationStateChange:self.activeConversation];

		NSString *path = [NSString stringWithFormat:@"/conversations/%@/logout", self.activeConversation.identifier];
		NSDictionary *payload = @{ @"token": self.activeConversation.token, @"logout": @{} };
		[ApptentiveSerialRequest enqueueRequestWithPath:path method:@"POST" payload:payload attachments:nil identifier:nil conversation:self.activeConversation authToken:Apptentive.shared.APIKey inContext:self.parentManagedObjectContext];

		_activeConversation = nil;

		return YES;
	} else {
		ApptentiveLogInfo(@"Attempting to log out, but no conversation is active.");
	}

	return NO;
}

#pragma mark - Conversation Token Fetching

- (void)fetchConversationToken:(ApptentiveConversation *)conversation {
	self.conversationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"POST" payload:conversation.conversationCreationJSON authToken:Apptentive.shared.APIKey delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.conversationOperation];
}

- (void)handleConversationStateChange:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation);
	if (conversation != nil) {
		NSDictionary *userInfo = @{ApptentiveConversationStateDidChangeNotificationKeyConversation: conversation};
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveConversationStateDidChangeNotification
															object:self
														  userInfo:userInfo];
	}

	if ([self.delegate respondsToSelector:@selector(conversationManager:conversationDidChangeState:)]) {
		[self.delegate conversationManager:self conversationDidChangeState:conversation];
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
		context.parentContext = self.parentManagedObjectContext;

		[context performBlock:^{
			[ApptentiveSerialRequest enqueueRequestWithPath:@"conversation" method:@"PUT" payload:payload conversation:self.activeConversation inContext:context];
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

		[context performBlock:^{
			[ApptentiveSerialRequest enqueueRequestWithPath:@"people" method:@"PUT" payload:diffs conversation:self.activeConversation inContext:context];
		}];

		[self saveConversation];
	}];

	[self.operationQueue addOperation:personDidChangeOperation];
}

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	NSBlockOperation *deviceDidChangeOperation = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		context.parentContext = self.parentManagedObjectContext;

		[context performBlock:^{
			[ApptentiveSerialRequest enqueueRequestWithPath:@"devices" method:@"PUT" payload:diffs conversation:self.activeConversation inContext:context];
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
	ApptentiveLogDebug(@"%@ %@ finished successfully.", operation.request.HTTPMethod, operation.request.URL.absoluteString);

	if (operation == self.conversationOperation) {
		[self processConversationResponse:(NSDictionary *)operation.responseObject];

		self.conversationOperation = nil;
	} else if (operation == self.manifestOperation) {
		[self processManifestResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];

		self.manifestOperation = nil;
	}
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error {
	if (error) {
		ApptentiveLogError(@"%@ %@ failed with error: %@", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);
	}

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.", operation.request.HTTPMethod, operation.request.URL.absoluteString, self.networkQueue.backoffDelay);
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	ApptentiveLogError(@"%@ %@ failed with error: %@. Not retrying.", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);

	if (operation == self.conversationOperation) {
		// This is a permanent failure. We should basically disable the SDK at this point.
		// TODO: disable the SDK until next launch
		self.conversationOperation = nil;
	} else if (operation == self.manifestOperation) {
		self.manifestOperation = nil;
	}
}

- (void)processConversationResponse:(NSDictionary *)conversationResponse {
	NSString *token = conversationResponse[@"token"];
	NSString *conversationID = conversationResponse[@"id"];
	NSString *personID = conversationResponse[@"person_id"];
	NSString *deviceID = conversationResponse[@"device_id"];

	if (token != nil) {
		[self.activeConversation setToken:token conversationID:conversationID personID:personID deviceID:deviceID];
		self.messageManager.localUserIdentifier = personID;

		if (self.activeConversation.state == ApptentiveConversationStateAnonymousPending) {
			self.activeConversation.state = ApptentiveConversationStateAnonymous;
		}

		[self saveConversation];

		[self handleConversationStateChange:self.activeConversation];
	}
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
	});
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

	self.manifestOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"interactions" method:@"GET" payload:nil authToken:self.activeConversation.token delegate:self dataSource:self.networkQueue];

	if (!self.activeConversation.token && self.conversationOperation) {
		[self.manifestOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.manifestOperation];
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
