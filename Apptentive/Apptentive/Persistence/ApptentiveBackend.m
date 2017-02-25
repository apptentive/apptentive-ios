//
//  ApptentiveBackend.m
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveBackend+Metrics.h"
#import "Apptentive_Private.h"
#import "ApptentiveDataManager.h"
#import "ApptentiveReachability.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveLog.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveSerialRequest+Record.h"
#import "ApptentiveFileAttachment.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveVersion.h"

#import "ApptentiveLegacyEvent.h"
#import "ApptentiveLegacySurveyResponse.h"

typedef NS_ENUM(NSInteger, ATBackendState) {
	ATBackendStateStarting,
	ATBackendStateWaitingForDataProtectionUnlock,
	ATBackendStateReady
};


@interface ApptentiveBackend ()

@property (readonly, strong, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, strong, nonatomic) ApptentiveNetworkQueue *networkQueue;
@property (readonly, strong, nonatomic) ApptentiveSerialNetworkQueue *serialNetworkQueue;

@property (assign, nonatomic) ATBackendState state;
@property (assign, nonatomic) BOOL working;
@property (assign, nonatomic) BOOL shouldStopWorking;
@property (assign, nonatomic) BOOL networkAvailable;

@property (copy, nonatomic) NSDictionary *currentCustomData;
@property (strong, nonatomic) NSTimer *messageRetrievalTimer;
@property (strong, nonatomic) ApptentiveDataManager *dataManager;
@property (strong, nonatomic) NSFetchedResultsController *unreadCountController;
@property (assign, nonatomic) NSUInteger previousUnreadCount;

@property (readonly, nonatomic, getter=isMessageCenterInForeground) BOOL messageCenterInForeground;
@property (copy, nonatomic) void (^backgroundFetchBlock)(UIBackgroundFetchResult);

@end


@implementation ApptentiveBackend

@synthesize supportDirectoryPath = _supportDirectoryPath;

- (instancetype)initWithAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath {
	self = [super init];

	if (self) {
		_APIKey = APIKey;
		_baseURL = baseURL;
		_storagePath = storagePath;

		_state = ATBackendStateStarting;
		_operationQueue = [[NSOperationQueue alloc] init];
		_operationQueue.maxConcurrentOperationCount = 1;
		_supportDirectoryPath = [[ApptentiveUtilities applicationSupportPath] stringByAppendingPathComponent:storagePath];

		if ([UIApplication sharedApplication] != nil && ![UIApplication sharedApplication].isProtectedDataAvailable) {
			_operationQueue.suspended = YES;
			_state = ATBackendStateWaitingForDataProtectionUnlock;

			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
				self.operationQueue.suspended = NO;
				self.state = ATBackendStateStarting;
			}];
		}

		[ApptentiveReachability sharedReachability];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForMessages) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoteNotificationInUIApplicationStateActive) name:UIApplicationDidBecomeActiveNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ApptentiveReachabilityStatusChanged object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageCheckingTimer) name:ApptentiveInteractionsDidUpdateNotification object:nil];

		[_operationQueue addOperationWithBlock:^{
			[self createSupportDirectoryIfNeeded];

			dispatch_sync(dispatch_get_main_queue(), ^{
				[self setUpCoreData];
			});

			[self startUp];

			[self finishStartup];
		}];
	}

	return self;
}

- (void)dealloc {
	[self.messageRetrievalTimer invalidate];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	@try {
		[self.serialNetworkQueue removeObserver:self forKeyPath:@"messageTaskCount"];
		[self.serialNetworkQueue removeObserver:self forKeyPath:@"messageSendProgress"];
	} @catch (NSException *_) {
	}
}

- (void)updateWorking {
	if (self.shouldStopWorking) {
		// Probably going into the background or being terminated.
		self.working = NO;
	} else if (self.state != ATBackendStateReady) {
		// Backend isn't ready yet.
		self.working = NO;
	} else if (self.networkAvailable && self.dataManager != nil && [self.dataManager persistentStoreCoordinator] != nil) {
		// API Key is set and the network and Core Data stack is up. Start working.
		self.working = YES;
	} else {
		// No API Key, no network, or no Core Data. Stop working.
		self.working = NO;
	}
}

#pragma mark Notification Handling

- (void)networkStatusChanged:(NSNotification *)notification {
	ApptentiveNetworkStatus status = [[ApptentiveReachability sharedReachability] currentNetworkStatus];
	if (status == ApptentiveNetworkNotReachable) {
		self.networkAvailable = NO;
	} else {
		self.networkAvailable = YES;
	}
	[self updateWorking];
}

- (void)stopWorking:(NSNotification *)notification {
	self.shouldStopWorking = YES;
	[self updateWorking];
}

- (void)startWorking:(NSNotification *)notification {
	self.shouldStopWorking = NO;
	[self updateWorking];
}

- (void)handleRemoteNotificationInUIApplicationStateActive {
	if ([Apptentive sharedConnection].pushUserInfo) {
		[[Apptentive sharedConnection] didReceiveRemoteNotification:[Apptentive sharedConnection].pushUserInfo fromViewController:[Apptentive sharedConnection].pushViewController];
	}
}

- (void)startMonitoringUnreadMessages {
	@autoreleasepool {
		if (self.unreadCountController != nil) {
			ApptentiveLogError(@"startMonitoringUnreadMessages called more than once!");
			return;
		}
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[self managedObjectContext]]];
		[request setFetchBatchSize:20];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		sortDescriptor = nil;

		NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"seenByUser == %@ AND sentByUser == %@", @(NO), @(NO)];
		request.predicate = unreadPredicate;

		NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[self managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
		newController.delegate = self;
		self.unreadCountController = newController;

		NSError *error = nil;
		if (![self.unreadCountController performFetch:&error]) {
			ApptentiveLogError(@"got an error loading unread messages: %@", error);
			//!! handle me
		} else {
			[self controllerDidChangeContent:self.unreadCountController];
		}

		request = nil;
	}
}

#pragma mark Accessors

- (void)setWorking:(BOOL)working {
	if (_working != working) {
		_working = working;
		if (_working) {
			[self.networkQueue resetBackoffDelay];
			[self.serialNetworkQueue resetBackoffDelay];

			[self.conversationManager resume];

			[self processQueuedRecords];
		} else {
			[self.conversationManager pause];

			[self.networkQueue cancelAllOperations];
			[self.serialNetworkQueue cancelAllOperations];

			self.serialNetworkQueue.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"SaveContext" expirationHandler:^{
				ApptentiveLogWarning(@"Background task expired");
			}];
		}

		[self updateMessageCheckingTimer];
	}
}

- (BOOL)isReady {
	return (self.state == ATBackendStateReady);
}

// TODO: App configuration should move back to backend.
- (ApptentiveAppConfiguration *)configuration {
	return self.conversationManager.configuration;
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

#pragma mark -

- (void)createSupportDirectoryIfNeeded {
	if (![[NSFileManager defaultManager] fileExistsAtPath:self->_supportDirectoryPath]) {
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:self->_supportDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(@"Unable to create storage path “%@”: %@", self->_supportDirectoryPath, error);
		}
	}
}

- (void)startUp {
	_networkQueue = [[ApptentiveNetworkQueue alloc] initWithBaseURL:self.baseURL token:self.APIKey SDKVersion:kApptentiveVersionString platform:@"iOS"];

	_conversationManager = [[ApptentiveConversationManager alloc] initWithStoragePath:_supportDirectoryPath operationQueue:_operationQueue networkQueue:_networkQueue parentManagedObjectContext:self.managedObjectContext];

	[self.conversationManager loadActiveConversation];
}

// Note: must be called on main thread
- (void)setUpCoreData {
	ApptentiveLogDebug(@"Setting up data manager");
	self.dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[ApptentiveUtilities resourceBundle] storagePath:[self supportDirectoryPath]];
	if (![self.dataManager setupAndVerify]) {
		ApptentiveLogError(@"Unable to setup and verify data manager.");
	} else if (![self.dataManager persistentStoreCoordinator]) {
		ApptentiveLogError(@"There was a problem setting up the persistent store coordinator!");
	}
}

- (void)finishStartup {
	_serialNetworkQueue = [[ApptentiveSerialNetworkQueue alloc] initWithBaseURL:self.baseURL token:self.APIKey SDKVersion:kApptentiveVersionString platform:@"iOS"	parentManagedObjectContext:self.managedObjectContext];

	[self.serialNetworkQueue addObserver:self forKeyPath:@"messageSendProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
	[self.serialNetworkQueue addObserver:self forKeyPath:@"messageTaskCount" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];

	self.state = ATBackendStateReady;
	dispatch_async(dispatch_get_main_queue(), ^{
		[ApptentiveFileAttachment addMissingExtensions];
	});

	[self networkStatusChanged:nil];
	[self startMonitoringAppLifecycleMetrics];
	[self startMonitoringUnreadMessages];

	NSString *legacyTaskPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"tasks.objects"];
	NSError *error;
	if ([[NSFileManager defaultManager] fileExistsAtPath:legacyTaskPath] && ![[NSFileManager defaultManager] removeItemAtPath:legacyTaskPath error:&error]) {
		ApptentiveLogError(@"Unable to delete migrated tasks: %@", error);
	}

	// Enqueue any unsent messages, events, or survey responses from <= v3.4
	NSManagedObjectContext *migrationContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	migrationContext.parentContext = self.managedObjectContext;

	[migrationContext performBlockAndWait:^{
		[ApptentiveMessage enqueueUnsentMessagesInContext:migrationContext];
		[ApptentiveLegacyEvent enqueueUnsentEventsInContext:migrationContext];
		[ApptentiveLegacySurveyResponse enqueueUnsentSurveyResponsesInContext:migrationContext];

		NSError *coreDataError;
		if (![migrationContext save:&coreDataError]) {
			ApptentiveLogError(@"Unable to save migration context: %@", coreDataError);
		}
	}];

	[self processQueuedRecords];
}

- (void)processQueuedRecords {
	if (self.isReady && self.working) {
		[self.serialNetworkQueue resume];
	}
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (controller == self.unreadCountController) {
		id<NSFetchedResultsSectionInfo> sectionInfo = [[self.unreadCountController sections] objectAtIndex:0];
		NSUInteger unreadCount = [sectionInfo numberOfObjects];
		if (unreadCount != self.previousUnreadCount) {
			if (unreadCount > self.previousUnreadCount && !self.messageCenterInForeground) {
				ApptentiveMessage *message = sectionInfo.objects.firstObject;
				[[Apptentive sharedConnection] showNotificationBannerForMessage:message];
			}
			self.previousUnreadCount = unreadCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveMessageCenterUnreadCountChangedNotification object:nil userInfo:@{ @"count": @(self.previousUnreadCount) }];
		}
	}
}

- (void)messageCenterWillDismiss:(ApptentiveMessageCenterViewController *)messageCenter {
}

#pragma mark - Messages

- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body {
	ApptentiveMessage *message = [ApptentiveMessage newInstanceWithBody:body attachments:nil];
	message.hidden = @NO;
	message.title = title;
	message.pendingState = @(ATPendingMessageStateComposing);
	message.sentByUser = @YES;
	message.automated = @YES;
	NSError *error = nil;
	if (![[self managedObjectContext] save:&error]) {
		ApptentiveLogError(@"Unable to send automated message with title: %@, body: %@, error: %@", title, body, error);
		message = nil;
	}

	return message;
}

- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message {
	message.pendingState = @(ATPendingMessageStateSending);

	return [self sendMessage:message];
}

- (BOOL)sendTextMessageWithBody:(NSString *)body {
	return [self sendTextMessageWithBody:body hiddenOnClient:NO];
}

- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden {
	return [self sendTextMessage:[self createTextMessageWithBody:body hiddenOnClient:hidden]];
}

- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden {
	ApptentiveMessage *message = [ApptentiveMessage newInstanceWithBody:body attachments:nil];
	message.sentByUser = @YES;
	message.seenByUser = @YES;
	message.hidden = @(hidden);

	if (!hidden) {
		[self attachCustomDataToMessage:message];
	}

	return message;
}

- (BOOL)sendTextMessage:(ApptentiveMessage *)message {
	message.pendingState = @(ATPendingMessageStateSending);

	return [self sendMessage:message];
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image {
	return [self sendImageMessageWithImage:image hiddenOnClient:NO];
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden {
	NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
	NSString *mimeType = @"image/jpeg";
	return [self sendFileMessageWithFileData:imageData andMimeType:mimeType hiddenOnClient:hidden];
}


- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType {
	return [self sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:NO];
}

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden {
	ApptentiveFileAttachment *fileAttachment = [ApptentiveFileAttachment newInstanceWithFileData:fileData MIMEType:mimeType name:nil];
	return [self sendCompoundMessageWithText:nil attachments:@[fileAttachment] hiddenOnClient:hidden];
}

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden {
	ApptentiveMessage *compoundMessage = [ApptentiveMessage newInstanceWithBody:text attachments:attachments];
	compoundMessage.pendingState = @(ATPendingMessageStateSending);
	compoundMessage.sentByUser = @YES;
	compoundMessage.hidden = @(hidden);

	return [self sendMessage:compoundMessage];
}

- (BOOL)sendMessage:(ApptentiveMessage *)message {
	NSAssert([NSThread isMainThread], @"-sendMessage: should only be called on main thread");

	ApptentiveMessageSender *sender = [ApptentiveMessageSender findSenderWithID:self.conversationManager.activeConversation.person.identifier inContext:self.managedObjectContext];
	if (sender) {
		message.sender = sender;
	}

	NSError *error;
	if (![[self managedObjectContext] save:&error]) {
		ApptentiveLogError(@"Error (%@) saving message: %@", error, message);
		return NO;
	}

	[ApptentiveSerialRequest enqueueMessage:message inContext:[self managedObjectContext]];

	[self processQueuedRecords];

	return YES;
}


#pragma mark Message Center

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController {
	return [self presentMessageCenterFromViewController:viewController withCustomData:nil];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
	if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
		// Only present Message Center UI in Active state.
		return NO;
	}

	self.currentCustomData = customData;

	if (!viewController) {
		ApptentiveLogError(@"Attempting to present Apptentive Message Center from a nil View Controller.");
		return NO;
	} else if (viewController.presentedViewController) {
		ApptentiveLogError(@"Attempting to present Apptentive Message Center from View Controller that is already presenting a modal view controller");
		return NO;
	}

	if (self.presentedMessageCenterViewController != nil) {
		ApptentiveLogInfo(@"Apptentive message center controller already shown.");
		return NO;
	}

	BOOL didShowMessageCenter = [[ApptentiveInteraction apptentiveAppInteraction] engage:ApptentiveEngagementMessageCenterEvent fromViewController:viewController];

	if (!didShowMessageCenter) {
		UINavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"NoPayloadNavigation"];

		[viewController presentViewController:navigationController animated:YES completion:nil];
	}

	return didShowMessageCenter;
}

- (void)attachCustomDataToMessage:(ApptentiveMessage *)message {
	if (self.currentCustomData) {
		[message addCustomDataFromDictionary:self.currentCustomData];
		// Only attach custom data to the first message.
		self.currentCustomData = nil;
	}
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	self.currentCustomData = nil;

	if (self.presentedMessageCenterViewController != nil) {
		UIViewController *vc = [self.presentedMessageCenterViewController presentingViewController];
		[vc dismissViewControllerAnimated:YES completion:^{
			completion();
		}];
		return;
	}

	if (completion) {
		// Call completion block even if we do nothing.
		completion();
	}
}

#pragma mark Message Polling

- (NSUInteger)unreadMessageCount {
	return self.previousUnreadCount;
}

- (void)updateMessageCheckingTimer {
	if (self.working) {
		if (self.messageCenterInForeground) {
			[self checkForMessagesAtRefreshInterval:self.configuration.messageCenter.foregroundPollingInterval];
		} else {
			[self checkForMessagesAtRefreshInterval:self.configuration.messageCenter.backgroundPollingInterval];
		}
	} else {
		[self stopMessageCheckingTimer];
	}
}

- (void)stopMessageCheckingTimer {
	if (self.messageRetrievalTimer) {
		[self.messageRetrievalTimer invalidate];
		self.messageRetrievalTimer = nil;
	}
}

- (void)checkForMessagesAtRefreshInterval:(NSTimeInterval)refreshInterval {
	@synchronized(self) {
		[self stopMessageCheckingTimer];

		self.messageRetrievalTimer = [NSTimer timerWithTimeInterval:refreshInterval target:self.conversationManager selector:@selector(checkForMessages) userInfo:nil repeats:YES];
		NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
		[mainRunLoop addTimer:self.messageRetrievalTimer forMode:NSDefaultRunLoopMode];
	}
}

- (void)messageCenterEnteredForeground {
	@synchronized(self) {
		_messageCenterInForeground = YES;

		[self.conversationManager checkForMessages];

		[self updateMessageCheckingTimer];
	}
}

- (void)messageCenterLeftForeground {
	@synchronized(self) {
		_messageCenterInForeground = NO;

		[self updateMessageCheckingTimer];

		if (self.presentedMessageCenterViewController) {
			self.presentedMessageCenterViewController = nil;
		}
	}
}

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler {
	self.backgroundFetchBlock = completionHandler;

	[self.conversationManager checkForMessages];
}

#pragma mark - Conversation manager delegate

- (void)conversationManagerMessageFetchCompleted:(BOOL)success {
	UIBackgroundFetchResult fetchResult = success ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed;

	if (self.backgroundFetchBlock) {
		self.backgroundFetchBlock(fetchResult);

		self.backgroundFetchBlock = nil;
	}
}

- (void)conversationManager:(ApptentiveConversationManager *)manager didLoadConversation:(ApptentiveConversation *)conversation {
	self.networkQueue.token = conversation.token;
	self.serialNetworkQueue.token = conversation.token;
}

#pragma mark Message send progress

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
	if (object == self.serialNetworkQueue && ([keyPath isEqualToString:@"messageSendProgress"] || [keyPath isEqualToString:@"messageTaskCount"])) {
		NSNumber *numberProgress = change[NSKeyValueChangeNewKey];
		float progress = [numberProgress isKindOfClass:[NSNumber class]] ? numberProgress.floatValue : 0.0;

		if (self.serialNetworkQueue.messageTaskCount > 0 && numberProgress.floatValue < 0.05) {
			progress = 0.05;
		} else if (self.serialNetworkQueue.messageTaskCount == 0) {
			progress = 0;
		}

		[self.messageDelegate backend:self messageProgressDidChange:progress];
	}
}

#pragma mark - Paths

- (NSString *)attachmentDirectoryPath {
	if (!self.supportDirectoryPath) {
		return nil;
	}
	NSString *newPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ApptentiveLogError(@"Failed to create attachments directory: %@", newPath);
		ApptentiveLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)cacheDirectoryPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

	NSString *newPath = [path stringByAppendingPathComponent:@"com.apptentive"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ApptentiveLogError(@"Failed to create support directory: %@", newPath);
		ApptentiveLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)imageCachePath {
	NSString *cachePath = [self cacheDirectoryPath];
	if (!cachePath) {
		return nil;
	}
	NSString *imageCachePath = [cachePath stringByAppendingPathComponent:@"images.cache"];
	return imageCachePath;
}

#pragma mark - Debugging

- (void)resetBackend {
	[self stopWorking:nil];

	NSError *error;

	if (![[NSFileManager defaultManager] removeItemAtPath:self.supportDirectoryPath error:&error]) {
		ApptentiveLogError(@"Unable to delete backend data");
	}
}

@end
