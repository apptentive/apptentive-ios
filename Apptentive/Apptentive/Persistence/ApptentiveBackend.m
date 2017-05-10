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
#import "ApptentiveLog.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveVersion.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveConfigurationRequest.h"
#import "ApptentivePayloadSender.h"

#import "ApptentiveLegacyEvent.h"
#import "ApptentiveLegacySurveyResponse.h"
#import "ApptentiveLegacyMessage.h"
#import "ApptentiveLegacyFileAttachment.h"


typedef NS_ENUM(NSInteger, ATBackendState) {
	ATBackendStateStarting,
	ATBackendStateWaitingForDataProtectionUnlock,
	ATBackendStateReady
};


@interface ApptentiveBackend ()

@property (strong, nonatomic) ApptentiveRequestOperation *configurationOperation;

@property (assign, nonatomic) ATBackendState state;
@property (assign, nonatomic) BOOL working;
@property (assign, nonatomic) BOOL shouldStopWorking;
@property (assign, nonatomic) BOOL networkAvailable;

@property (strong, nonatomic) NSTimer *messageRetrievalTimer;
@property (strong, nonatomic) ApptentiveDataManager *dataManager;

@property (readonly, nonatomic, getter=isMessageCenterInForeground) BOOL messageCenterInForeground;

@end


@implementation ApptentiveBackend

@synthesize supportDirectoryPath = _supportDirectoryPath;

- (instancetype)initWithAppKey:(NSString *)appKey signature:(NSString *)signature baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath {
	self = [super init];

	if (self) {
		_appKey = appKey;
		_appSignature = signature;
		_baseURL = baseURL;
		_storagePath = storagePath;

		_state = ATBackendStateStarting;
		_operationQueue = [[NSOperationQueue alloc] init];
		_operationQueue.maxConcurrentOperationCount = 1;
		_operationQueue.name = @"Apptentive Operation Queue";
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

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoteNotificationInUIApplicationStateActive) name:UIApplicationDidBecomeActiveNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ApptentiveReachabilityStatusChanged object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMessageCheckingTimer) name:ApptentiveInteractionsDidUpdateNotification object:nil];

		[_operationQueue addOperationWithBlock:^{
			[self createSupportDirectoryIfNeeded];

			dispatch_sync(dispatch_get_main_queue(), ^{
				[self setUpCoreData];
			});

			[self loadConfiguration];
			
			[self startUp];
		}];
	}

	return self;
}

- (void)dealloc {
	[self.messageRetrievalTimer invalidate];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark Accessors

- (void)setWorking:(BOOL)working {
	if (_working != working) {
		_working = working;
		if (_working) {
#if APPTENTIVE_DEBUG
			[Apptentive.shared checkSDKConfiguration];


			self.configuration.expiry = [NSDate distantPast];
#endif
			if ([self.configuration.expiry timeIntervalSinceNow] <= 0) {
				[self fetchConfiguration];
			}

			[self.client resetBackoffDelay];

			[self.conversationManager resume];

			[self processQueuedRecords];
		} else {
			[self.conversationManager pause];

			[self.payloadSender cancelNetworkOperations];

			self.payloadSender.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"SaveContext" expirationHandler:^{
				ApptentiveLogWarning(@"Background task expired");
			}];
		}

		[self updateMessageCheckingTimer];
	}
}

- (BOOL)isReady {
	return (self.state == ATBackendStateReady);
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

#pragma mark -

- (void)fetchConfiguration {
	if (self.configurationOperation != nil || !self.working) {
		return;
	}

	self.configurationOperation = [self.client requestOperationWithRequest:[[ApptentiveConfigurationRequest alloc] initWithConversationIdentifier:self.conversationManager.activeConversation.identifier] delegate:self];

	if (!self.conversationManager.activeConversation && self.conversationManager.conversationOperation) {
		[self.configurationOperation addDependency:self.conversationManager.conversationOperation];
	}

	[self.client.operationQueue addOperation:self.configurationOperation];
}

- (void)createSupportDirectoryIfNeeded {
	if (![[NSFileManager defaultManager] fileExistsAtPath:self->_supportDirectoryPath]) {
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:self->_supportDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(@"Unable to create storage path “%@”: %@", self->_supportDirectoryPath, error);
		}
	}
}

- (void)startUp {
	_client = [[ApptentiveClient alloc] initWithBaseURL:self.baseURL appKey:self.appKey appSignature:self.appSignature];

	_conversationManager = [[ApptentiveConversationManager alloc] initWithStoragePath:self.supportDirectoryPath operationQueue:self.operationQueue client:self.client parentManagedObjectContext:self.managedObjectContext];
	self.conversationManager.delegate = self;

	_payloadSender = [[ApptentivePayloadSender alloc] initWithBaseURL:self.baseURL appKey:self.appKey appSignature:self.appSignature managedObjectContext:self.managedObjectContext];

	_imageCache = [[NSURLCache alloc] initWithMemoryCapacity:1 * 1024 * 1024 diskCapacity:10 * 1024 * 1024 diskPath:[self imageCachePath]];

	[self.conversationManager loadActiveConversation];

	[self.conversationManager.activeConversation checkForDiffs];
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

- (void)loadConfiguration {
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self configurationPath]]) {
		self->_configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:[self configurationPath]];
	} else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ATConfigurationSDKVersionKey"]) {
		self->_configuration = [[ApptentiveAppConfiguration alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
		if ([self saveConfiguration]) {
			[ApptentiveAppConfiguration deleteMigratedData];
		}
	} else {
		self->_configuration = [[ApptentiveAppConfiguration alloc] init];
	}
}

- (void)finishStartupWithToken:(NSString *)token {
	self.client.authToken = token;

	self.state = ATBackendStateReady;

	[self networkStatusChanged:nil];
	[self startMonitoringAppLifecycleMetrics];
}

- (void)migrateLegacyCoreDataAndTaskQueueForConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(conversation, @"Trying to migrate nil conversation");
	ApptentiveAssertTrue(conversation.state == ApptentiveConversationStateLegacyPending, @"Trying to migrate conversation that is not a legacy conversation (%@)", NSStringFromApptentiveConversationState(conversation.state));

	if (conversation.state != ApptentiveConversationStateLegacyPending) {
		return;
	}

	NSString *legacyTaskPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"tasks.objects"];
	NSError *error;
	if ([[NSFileManager defaultManager] fileExistsAtPath:legacyTaskPath] && ![[NSFileManager defaultManager] removeItemAtPath:legacyTaskPath error:&error]) {
		ApptentiveLogError(@"Unable to delete migrated tasks: %@", error);
	}

	// Enqueue any unsent messages, events, or survey responses from <= v3.4
	NSManagedObjectContext *migrationContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	migrationContext.parentContext = self.managedObjectContext;

	[migrationContext performBlockAndWait:^{
		[ApptentiveLegacyFileAttachment addMissingExtensionsInContext:migrationContext];
		[ApptentiveLegacyMessage enqueueUnsentMessagesInContext:migrationContext forConversation:conversation];
		[ApptentiveLegacyEvent enqueueUnsentEventsInContext:migrationContext forConversation:conversation];
		[ApptentiveLegacySurveyResponse enqueueUnsentSurveyResponsesInContext:migrationContext forConversation:conversation];

		NSError *coreDataError;
		if (![migrationContext save:&coreDataError]) {
			ApptentiveLogError(@"Unable to save migration context: %@", coreDataError);
		}
	}];

	[self processQueuedRecords];
}

#pragma mark Apptentive request operation delegate

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	if (operation == self.configurationOperation) {
		[self processConfigurationResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];

		self.configurationOperation = nil;
	}
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	if (operation == self.configurationOperation) {
		self.configurationOperation = nil;
	}
}

- (void)processQueuedRecords {
	if (self.isReady && self.working && self.conversationManager.activeConversation.token != nil) {
		[self.payloadSender createOperationsForQueuedRequestsInContext:self.managedObjectContext];
	}
}

- (void)processConfigurationResponse:(NSDictionary *)configurationResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_configuration = [[ApptentiveAppConfiguration alloc] initWithJSONDictionary:configurationResponse cacheLifetime:cacheLifetime];

	[self saveConfiguration];
}

- (BOOL)saveConfiguration {
	@synchronized(self.configuration) {
		return [NSKeyedArchiver archiveRootObject:self.configuration toFile:[self configurationPath]];
	}
}

#pragma mark Message Center

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController {
	return [self presentMessageCenterFromViewController:viewController withCustomData:nil];
}

- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(NSDictionary *)customData {
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
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

#pragma mark Person/Device management

- (void)scheduleDeviceUpdate {
	[self.operationQueue addOperationWithBlock:^{
		[self.conversationManager.activeConversation checkForDeviceDiffs];
	}];
}

- (void)schedulePersonUpdate {
	[self.operationQueue addOperationWithBlock:^{
		[self.conversationManager.activeConversation checkForPersonDiffs];
	}];
}

#pragma mark Message Polling

- (NSUInteger)unreadMessageCount {
	return self.conversationManager.messageManager.unreadCount;
}

- (void)updateMessageCheckingTimer {
	if (self.working) {
		if (self.messageCenterInForeground) {
			self.conversationManager.messageManager.pollingInterval = self.configuration.messageCenter.foregroundPollingInterval;
		} else {
			self.conversationManager.messageManager.pollingInterval = self.configuration.messageCenter.backgroundPollingInterval;
		}
	} else {
		[self.conversationManager.messageManager stopPolling];
	}
}

- (void)messageCenterEnteredForeground {
	@synchronized(self) {
		_messageCenterInForeground = YES;

		[self.conversationManager.messageManager checkForMessages];

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

#pragma mark - Conversation manager delegate

- (void)conversationManager:(ApptentiveConversationManager *)manager conversationDidChangeState:(ApptentiveConversation *)conversation {
	// Anonymous pending conversations will not yet have a token, so we can't finish starting up yet in that case.
	if (conversation.state != ApptentiveConversationStateAnonymousPending) {
		if (self.state != ATBackendStateReady) {
			[self finishStartupWithToken:conversation.token];
		}

		if (conversation.state == ApptentiveConversationStateAnonymous) {
			NSString *conversationIdentifier = conversation.identifier;
			ApptentiveAssertNotNil(conversation, @"Conversation id is nil");

			if (conversationIdentifier != nil) {
				[self.payloadSender updateQueuedRequestsInContext:self.managedObjectContext missingConversationIdentifier:conversationIdentifier];
			}
		}
	}
}

#pragma mark - Paths

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

- (NSString *)configurationPath {
	return [self.supportDirectoryPath stringByAppendingPathComponent:@"configuration"];
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
