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
#import "ApptentiveMessage.h"
#import "ApptentivePerson.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveSerialRequest.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";
static NSString *const ConversationFilename = @"conversation-v1.archive";
static NSString *const ManifestFilename = @"manifest-v1.archive";

@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;

@property (strong, nonatomic, nullable) ApptentiveRequestOperation *messageOperation;
@property (strong, nonatomic, nullable) ApptentiveRequestOperation *manifestOperation;

@property (readonly, nonatomic) NSString *metadataPath;
@property (readonly, nonatomic) NSString *conversationPath;
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
 * Attempts to load an active conversation. Returns <code>false</code> if active conversation is
 * missing or cannot be loaded
 */

/**
 Attempts to load a logged-in conversation. If no conversations are found, a new one will be created.
 If only logged-out conversations are found, returns false.

 @return `YES` if a conversation was loaded
 */
- (BOOL)loadActiveConversation {
	// resolving metadata
	_conversationMetadata = [self resolveMetadata];

	// attempt to load existing conversation
	_activeConversation = [self loadConversation];
	//dispatchDebugEvent(EVT_CONVERSATION_LOAD_ACTIVE, activeConversation != null);

	if (self.activeConversation != nil) {
		self.activeConversation.delegate = self;

		[self notifyConversationStateDidChange];
		return true;
	}

	return false;
}

/**
 Returns the logged-in conversation. If no conversations are found, a new one is created.
 If only logged-out conversations are found, returns `nil`.

 @return the conversation that was loaded, or `nil` in the case that no conversation was loaded.
 */
- (ApptentiveConversation *)loadConversation {
    // if no user was logged in previously - we might have a default conversation
    ApptentiveLogDebug(@"Loading logged-in conversation...");
    ApptentiveConversationMetadataItem *loggedInItem = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.state == ApptentiveConversationStateLoggedIn;
    }];
    
    if (loggedInItem != nil) {
		return [self loadConversation:loggedInItem];
    }

	// if no user was logged in previously - we might have an anonymous conversation
	ApptentiveLogDebug(@"Loading anonymous conversation...");
	ApptentiveConversationMetadataItem *anonymousItem = [self.conversationMetadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
		return item.state == ApptentiveConversationStateAnonymous || item.state == ApptentiveConversationStateAnonymousPending;
	}];

	if (anonymousItem != nil) {
		ApptentiveConversation *conversation = [self loadConversation: anonymousItem];
		if (conversation.state == ApptentiveConversationStateAnonymousPending) { // was conversation token fetched?
			[self fetchConversationToken:conversation];
		}

		return conversation;
	}

	if (self.conversationMetadata.items.count == 0) {
		ApptentiveLogDebug(@"Can't load conversation: creating anonymous conversation...");
		ApptentiveConversation *anonymousConversation = [[ApptentiveConversation alloc] init];
		anonymousConversation.state = ApptentiveConversationStateAnonymousPending;
		[self fetchConversationToken:anonymousConversation];
		
		return anonymousConversation;
	}

	ApptentiveLogDebug(@"Can't load conversation: only 'logged-out' conversations available");
	return nil;
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)item {
	_conversationPath = [self conversationPathForFilename:item.fileName];
	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithFile:self.conversationPath];
	conversation.state = item.state;

	return conversation;
}

- (BOOL)endActiveConversation {
	if (self.activeConversation != nil) {
		self.activeConversation.state = ApptentiveConversationStateLoggedOut;
		// TODO: notify people?
		return YES;
	}

	return NO;
}

#pragma mark - Conversation fetching

- (void)fetchConversationToken:(ApptentiveConversation *)conversation {
	NSAssert(conversation.state == ApptentiveConversationStateAnonymousPending, @"Only anonyous pending conversations should load tokens");

	self.conversationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"POST" payload:conversation.conversationCreationJSON delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.conversationOperation];
}

- (void)notifyConversationStateDidChange {
	if ([self.delegate respondsToSelector:@selector(conversationManager:conversationDidChangeState:)]) {
		[self.delegate conversationManager:self conversationDidChangeState:self.activeConversation];
	}
}

- (void)checkForMessages {
	self.messageOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	if (!self.activeConversation.token && self.conversationOperation) {
		[self.messageOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.messageOperation];
}

- (void)resume {
#if APPTENTIVE_DEBUG
	[Apptentive.shared checkSDKConfiguration];

	self.manifest.expiry = [NSDate distantPast];
#endif

	if ([self.manifest.expiry timeIntervalSinceNow] <= 0) {
		[self fetchEngagementManifest];
	}

	[self checkForMessages];
}

- (void)pause {
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
			[ApptentiveSerialRequest enqueueRequestWithPath:@"conversation" method:@"PUT" payload:payload attachments:nil identifier:nil inContext:context];
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
			[ApptentiveSerialRequest enqueueRequestWithPath:@"people" method:@"PUT" payload:diffs attachments:nil identifier:nil inContext:context];
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
			[ApptentiveSerialRequest enqueueRequestWithPath:@"devices" method:@"PUT" payload:diffs attachments:nil identifier:nil inContext:context];
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
	} else if (operation == self.messageOperation) {
		[self processMessagesResponse:(NSDictionary *)operation.responseObject];

		self.messageOperation = nil;
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
		self.conversationOperation = nil;
	} else if (operation == self.manifestOperation) {
		self.manifestOperation = nil;
	} else if (operation == self.messageOperation) {
		self.messageOperation = nil;
	}
}

- (void)processConversationResponse:(NSDictionary *)conversationResponse {
	NSString *token = conversationResponse[@"token"];
	NSString *conversationID = conversationResponse[@"id"];
	NSString *personID = conversationResponse[@"person_id"];
	NSString *deviceID = conversationResponse[@"device_id"];

	if (token != nil) {
		[self.activeConversation setToken:token conversationID:conversationID personID:personID deviceID:deviceID];

		[self saveConversation];

		[self notifyConversationStateDidChange];
	}
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
	});
}

- (void)processMessagesResponse:(NSDictionary *)response {
	NSArray *messages = response[@"items"];

	if ([messages isKindOfClass:[NSArray class]]) {
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		context.parentContext = self.parentManagedObjectContext;

		[context performBlock:^{
			NSString *lastMessageID = nil;

			for (NSDictionary *messageJSON in messages) {
				ApptentiveMessage *message = [ApptentiveMessage messageWithJSON:messageJSON inContext:context];

				if (message) {
					if ([self.activeConversation.person.identifier isEqualToString:message.sender.apptentiveID]) {
						message.sentByUser = @(YES);
						message.seenByUser = @(YES);
					}

					message.pendingState = @(ATPendingMessageStateConfirmed);

					lastMessageID = message.apptentiveID;
				}
			}

			NSError *error = nil;
			if (![context save:&error]) {
				ApptentiveLogError(@"Failed to save received messages: %@", error);
				return;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *mainContextSaveError;
				if (![self.parentManagedObjectContext save:&mainContextSaveError]) {
					ApptentiveLogError(@"Failed to save received messages in main context: %@", error);
				}

				if ([self.delegate respondsToSelector:@selector(conversationManagerMessageFetchCompleted:)]) {
					[self.delegate conversationManagerMessageFetchCompleted:YES];
				}

				[self.activeConversation didDownloadMessagesUpTo:lastMessageID];
			});
		}];
	} else {
		ApptentiveLogError(@"Expected array of dictionaries for message response");
		if ([self.delegate respondsToSelector:@selector(conversationManagerMessageFetchCompleted:)]) {
			[self.delegate conversationManagerMessageFetchCompleted:NO];
		}
	}
}

- (BOOL)saveConversation {
	@synchronized(self.activeConversation) {
		return [NSKeyedArchiver archiveRootObject:self.activeConversation toFile:[self conversationPath]];
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

	self.manifestOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"interactions" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

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

- (NSString *)conversationPathForFilename:(NSString *)filename {
	return [self.storagePath stringByAppendingPathComponent:filename];
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
