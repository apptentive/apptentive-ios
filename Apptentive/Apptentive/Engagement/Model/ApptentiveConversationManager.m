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
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveMessage.h"
#import "ApptentivePerson.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveSerialRequest.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";
static NSString *const ConversationFilename = @"conversation-v1.archive";
static NSString *const ManifestFilename = @"manifest-v1.archive";
static NSString *const ConfigurationFilename = @"configuration-v1.archive";

@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;

@property (strong, nonatomic) ApptentiveRequestOperation *conversationOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *configurationOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *messageOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *manifestOperation;

@property (strong, nonatomic) ApptentiveConversation *pendingConversation;

@property (readonly, nonatomic) NSString *metadataPath;
@property (readonly, nonatomic) NSString *conversationPath;
@property (readonly, nonatomic) NSString *configurationPath;
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

- (BOOL)loadActiveConversation {
    // resolve metadata
    _conversationMetadata = [self resolveMetadata];
    
    // try to load conversaton
    _activeConversation = [self loadActiveConversationFromMetadata:_conversationMetadata];
    if (_activeConversation) {
        _activeConversation.delegate = self;
        [self notifyConversationDidBecomeActive];
        return YES;
    }
    
    // no conversation - fetch one
    [self fetchConversationToken];
    
    return NO;
}

- (ApptentiveConversation *)loadActiveConversationFromMetadata:(ApptentiveConversationMetadata *)metadata {
    // if the user was logged in previously - we should have an active conversation
    ApptentiveLogDebug(@"Loading active conversation...");
    ApptentiveConversationMetadataItem *activeItem = [metadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.isActive;
    }];
    
    if (activeItem) {
        return [self loadConversation:activeItem];
    }
    
    // if no user was logged in previously - we might have a default conversation
    ApptentiveLogDebug(@"Loading default conversation...");
    ApptentiveConversationMetadataItem *defaultItem = [metadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.isDefault;
    }];
    
    if (defaultItem) {
		self.activeConversation = [self loadConversation:defaultItem];
        return self.activeConversation;
    }
    
    // TODO: check for legacy conversations
    ApptentiveLogDebug(@"Can't load conversation");
    return nil;
}

- (void)notifyConversationDidBecomeActive {
	if ([self.delegate respondsToSelector:@selector(conversationManager:didLoadConversation:)]) {
		[self.delegate conversationManager:self didLoadConversation:self.activeConversation];
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
//#if APPTENTIVE_DEBUG
//	[Apptentive.shared checkSDKConfiguration];
//
//
//	self.configuration.expiry = [NSDate distantPast];
//	self.manifest.expiry = [NSDate distantPast];
//#endif
//
//	[self.activeConversation checkForDiffs];
//
//	if ([self.configuration.expiry timeIntervalSinceNow] <= 0) {
//		[self fetchConfiguration];
//	}
//
//	if ([self.manifest.expiry timeIntervalSinceNow] <= 0) {
//		[self fetchEngagementManifest];
//	}
//
//	[self checkForMessages];
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
	} else if (operation == self.configurationOperation) {
		[self processConfigurationResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];

		self.configurationOperation = nil;
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
	} else if (operation == self.configurationOperation) {
		self.configurationOperation = nil;
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
		[self.pendingConversation setToken:token conversationID:conversationID personID:personID deviceID:deviceID];

		self.activeConversation = self.pendingConversation;

		[self saveConversation];

		[self notifyConversationDidBecomeActive];
	}
}

- (void)processConfigurationResponse:(NSDictionary *)configurationResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_configuration = [[ApptentiveAppConfiguration alloc] initWithJSONDictionary:configurationResponse cacheLifetime:cacheLifetime];

	[self saveConfiguration];
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

- (BOOL)saveConfiguration {
	@synchronized(self.configuration) {
		return [NSKeyedArchiver archiveRootObject:self.configuration toFile:[self configurationPath]];
	}
}

- (BOOL)saveManifest {
	@synchronized(self.manifest) {
		return [NSKeyedArchiver archiveRootObject:_manifest toFile:[self manifestPath]];
	}
}

#pragma mark - Private

- (void)fetchConversationToken {
	if (self.conversationOperation != nil || self.activeConversation.token != nil) {
		return;
	}

	self.pendingConversation = [[ApptentiveConversation alloc] init];

	self.conversationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"POST" payload:self.activeConversation.conversationCreationJSON delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.conversationOperation];
}

- (void)fetchConfiguration {
	if (self.configurationOperation != nil) {
		return;
	}

	self.configurationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation/configuration" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	if (!self.activeConversation.token && self.conversationOperation) {
		[self.configurationOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.configurationOperation];
}

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

- (void)setActiveConversation:(ApptentiveConversation *)conversation {
	_activeConversation = conversation;

	ApptentiveConversationMetadataItem *activeMetadataItem = [self.conversationMetadata setActiveConversation:conversation];
	[self saveMetadata];

	_conversationPath = [self conversationPathForFilename:activeMetadataItem.fileName];
}

- (void)scheduleConversationSave {
	[self.operationQueue addOperationWithBlock:^{
		if (![self saveConversation]) {
			ApptentiveLogError(@"Error saving active conversation.");
		}
	}];
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)metadataItem {
	_conversationPath = [self conversationPathForFilename:metadataItem.fileName];
	return [NSKeyedUnarchiver unarchiveObjectWithFile:self.conversationPath];
}

#pragma mark - Paths

- (NSString *)metadataPath {
	return [self.storagePath stringByAppendingPathComponent:ConversationMetadataFilename];
}

- (NSString *)configurationPath {
	return [self.storagePath stringByAppendingPathComponent:ConfigurationFilename];
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
