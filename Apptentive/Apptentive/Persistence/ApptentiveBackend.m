//
//  ApptentiveBackend.m
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveBackend+Engagement.h"
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
#import "ApptentiveSafeCollections.h"
#import "ApptentiveInteraction.h"

#import "ApptentiveLegacyEvent.h"
#import "ApptentiveLegacySurveyResponse.h"
#import "ApptentiveLegacyMessage.h"
#import "ApptentiveLegacyFileAttachment.h"

@import CoreTelephony;

NS_ASSUME_NONNULL_BEGIN

NSString *const ApptentiveAuthenticationDidFailNotification = @"ApptentiveAuthenticationDidFailNotification";
NSString *const ApptentiveAuthenticationDidFailNotificationKeyErrorType = @"errorType";
NSString *const ApptentiveAuthenticationDidFailNotificationKeyErrorMessage = @"errorMessage";
NSString *const ApptentiveAuthenticationDidFailNotificationKeyConversationIdentifier = @"conversationIdentifier";
NSString *const ATInteractionAppEventLabelLaunch = @"launch";
NSString *const ATInteractionAppEventLabelExit = @"exit";


@interface ApptentiveBackend ()

@property (nullable, strong, nonatomic) ApptentiveRequestOperation *configurationOperation;

@property (assign, nonatomic) ApptentiveBackendState state;

@property (strong, nonatomic) CTTelephonyNetworkInfo *telephonyNetworkInfo;

@property (strong, nonatomic) NSTimer *messageRetrievalTimer;
@property (strong, nonatomic) ApptentiveDataManager *dataManager;
@property (readonly, nonatomic) ApptentiveMessageManager *messageManager;

@property (readonly, nonatomic, getter=isMessageCenterInForeground) BOOL messageCenterInForeground;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (strong, nonatomic) ApptentiveReachability *reachability;

@end


@implementation ApptentiveBackend

@synthesize supportDirectoryPath = _supportDirectoryPath;

- (instancetype)initWithApptentiveKey:(NSString *)apptentiveKey signature:(NSString *)signature baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue {
	self = [super init];

	if (self) {
		_apptentiveKey = apptentiveKey;
		_apptentiveSignature = signature;
		_baseURL = baseURL;
		_storagePath = storagePath;

		_state = ApptentiveBackendStateStarting;
		_operationQueue = operationQueue;
		_supportDirectoryPath = [[ApptentiveUtilities applicationSupportPath] stringByAppendingPathComponent:storagePath];

		if ([UIApplication sharedApplication] != nil && ![UIApplication sharedApplication].isProtectedDataAvailable) {
			_operationQueue.suspended = YES;
			_state = ApptentiveBackendStateWaitingForDataProtectionUnlock;

			__weak ApptentiveBackend *weakSelf = self;
			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *_Nonnull note) {
                ApptentiveBackend *strongSelf = weakSelf;
                if (strongSelf) {
                    strongSelf.operationQueue.suspended = NO;
                    strongSelf.state = ApptentiveBackendStateStarting;
                }
			}];
		}

		_reachability = [[ApptentiveReachability alloc] initWithHostname:self.baseURL.host];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRemoteNotificationInUIApplicationStateActive) name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ApptentiveReachabilityStatusChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apptentiveInteractionsDidUpdateNotification:) name:ApptentiveInteractionsDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationDidFailNotification:) name:ApptentiveAuthenticationDidFailNotification object:nil];

		[self updateAndMonitorDeviceValues];

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

/**
 Set up class properties on ApptentiveDevice and monitor for changes
 */
- (void)updateAndMonitorDeviceValues {
	[ApptentiveDevice getPermanentDeviceValues];

	__weak ApptentiveBackend *weakSelf = self;
	if ([CTTelephonyNetworkInfo class]) {
		_telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
		ApptentiveDevice.carrierName = _telephonyNetworkInfo.subscriberCellularProvider.carrierName;

		_telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier * _Nonnull carrier) {
			ApptentiveBackend *strongSelf = weakSelf;
			ApptentiveDevice.carrierName = carrier.carrierName;
			ApptentiveLogDebug(@"Carrier changed to %@. Updating device.", ApptentiveDevice.carrierName);
			[strongSelf.operationQueue addOperationWithBlock:^{
				[strongSelf scheduleDeviceUpdate]; // Must happen on our queue
			}];
		};
	}

	ApptentiveDevice.contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
	[NSNotificationCenter.defaultCenter addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
		ApptentiveBackend *strongSelf = weakSelf;
		ApptentiveDevice.contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory; // Must happen on main queue
		ApptentiveLogDebug(@"Content size category changed to %@. Updating device.", ApptentiveDevice.contentSizeCategory);
		[strongSelf.operationQueue addOperationWithBlock:^{
			[strongSelf scheduleDeviceUpdate]; // Must happen on our queue
		}];
	}];

	[[NSNotificationCenter defaultCenter] addObserverForName:NSSystemTimeZoneDidChangeNotification object:nil queue:self.operationQueue usingBlock:^(NSNotification * _Nonnull note) {
		ApptentiveLogDebug(@"System time zone changed to %@. Updating device.", NSTimeZone.systemTimeZone);
		ApptentiveBackend *strongSelf = weakSelf;
		[strongSelf scheduleDeviceUpdate];
	}];
}

#pragma mark Notification Handling

- (void)networkStatusChanged:(NSNotification *)notification {
	[self updateNetworkingForCurrentNetworkStatus];
}

- (void)applicationWillTerminateNotification:(NSNotification *)notification {
	[self addExitMetric];
	[self shutDown];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	[self addExitMetric];
	[self shutDown];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification {
	[self resume];
	[self addLaunchMetric];
}

- (void)apptentiveInteractionsDidUpdateNotification:(NSNotification *)notification {
	[self.operationQueue addOperationWithBlock:^{
        [self updateMessageCheckingTimer];
	}];
}

- (void)handleRemoteNotificationInUIApplicationStateActive {
	if ([Apptentive sharedConnection].pushUserInfo) {
		[[Apptentive sharedConnection] didReceiveRemoteNotification:[Apptentive sharedConnection].pushUserInfo fromViewController:[Apptentive sharedConnection].pushViewController];
	}
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

#pragma mark - As-needed tasks

- (void)fetchConfigurationIfNeeded {
	ApptentiveConversation *conversation = self.conversationManager.activeConversation;

	if (self.configurationOperation != nil || conversation.identifier == nil || !self.networkAvailable ||   [self.configuration.expiry timeIntervalSinceNow] > 0) {
		return;
	}

	ApptentiveRequestOperationCallback *callback = [ApptentiveRequestOperationCallback new];
	callback.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
        [self processConfigurationResponse:(NSDictionary *)operation.responseObject cacheLifetime:operation.cacheLifetime];
        self.configurationOperation = nil;
	};
	callback.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
        self.configurationOperation = nil;
	};

	self.configurationOperation = [self.client requestOperationWithRequest:[[ApptentiveConfigurationRequest alloc] initWithConversationIdentifier:conversation.identifier] token:conversation.token delegate:callback];

	if (!self.conversationManager.activeConversation && self.conversationManager.conversationOperation) {
		[self.configurationOperation addDependency:self.conversationManager.conversationOperation];
	}

	[self.client.networkQueue addOperation:self.configurationOperation];
}

- (void)createSupportDirectoryIfNeeded {
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.supportDirectoryPath]) {
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:self.supportDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(@"Unable to create storage path “%@”: %@", self.supportDirectoryPath, error);
		}
	}
}

#pragma mark - Lifecycle

- (void)startUp {
	ApptentiveAssertOperationQueue(self.operationQueue);

	_client = [[ApptentiveClient alloc] initWithBaseURL:self.baseURL apptentiveKey:self.apptentiveKey apptentiveSignature:self.apptentiveSignature delegateQueue:self.operationQueue];

	_conversationManager = [[ApptentiveConversationManager alloc] initWithStoragePath:self.supportDirectoryPath operationQueue:self.operationQueue client:self.client parentManagedObjectContext:self.managedObjectContext];
	self.conversationManager.delegate = self;

	_payloadSender = [[ApptentivePayloadSender alloc] initWithBaseURL:self.baseURL apptentiveKey:self.apptentiveKey apptentiveSignature:self.apptentiveSignature managedObjectContext:self.managedObjectContext delegateQueue:self.operationQueue];

	self.state = ApptentiveBackendStatePayloadDatabaseAvailable;

	[self.conversationManager loadActiveConversation];

	[self completeStartupAndResumeTasks];

	[self addLaunchMetric];
}

// This is called when we're about to enter the background
- (void)shutDown {
	ApptentiveLogVerbose(@"Shutting down backend");
	self.state = ApptentiveBackendStateShuttingDown;

	[self.operationQueue addOperationWithBlock:^{
		[self.conversationManager pause];
	}];

	ApptentiveLogVerbose(@"Operations in background queue: %@", [self.operationQueue.operations valueForKeyPath:@"name"]);
	ApptentiveLogVerbose(@"operations in payload network queue: %@", [self.payloadSender.networkQueue.operations valueForKeyPath:@"name"]);

	// Asynchronous tasks off the main thread will not be given a chance to complete automatically.
	// We create a background task to clear out our operation queue and the payload sender queue.
	self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Wind Down Backend" expirationHandler:^{
		ApptentiveLogError(@"Background task (%ld) did not complete in time.", (unsigned long)self.backgroundTaskIdentifier);
		[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
	}];

	// Here, we cancel any ongoing network operations in the payload sender.
	[self.payloadSender cancelNetworkOperations];

	// Create an operation to end the background task.
	NSBlockOperation *completeBackgroundTaskOperation = [NSBlockOperation blockOperationWithBlock:^{
		ApptentiveLogDebug(@"All background operations finished. Exiting.");
		[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
	}];

	completeBackgroundTaskOperation.name = @"Complete background task";

	// If there is a save operation in the queue, add it as a cross-queue dependency.
	NSOperation *saveContextOperation = self.payloadSender.saveContextOperation;

	if (saveContextOperation) {
		[completeBackgroundTaskOperation addDependency:saveContextOperation];
	}

	// Add the "complete background task" operation to the end of our (serial) background queue.
	[self.operationQueue addOperation:completeBackgroundTaskOperation];
}

// This is called on a warm launch
- (void)resume {
	if (self.managedObjectContext != nil) {
		self.state = ApptentiveBackendStatePayloadDatabaseAvailable;
	}

	[self completeStartupAndResumeTasks];

	[self completeHousekeepingTasks];
}

// Note: must be called on main thread
- (void)setUpCoreData {
	ApptentiveLogVerbose(ApptentiveLogTagStorage, @"Setting up data manager");
	self.dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[ApptentiveUtilities resourceBundle] storagePath:[self supportDirectoryPath]];
	if (![self.dataManager setupAndVerify]) {
		ApptentiveLogError(ApptentiveLogTagStorage, @"Unable to setup and verify data manager.");
	} else if (![self.dataManager persistentStoreCoordinator]) {
		ApptentiveLogError(ApptentiveLogTagStorage, @"There was a problem setting up the persistent store coordinator!");
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

// This is called on warm and cold launch
- (void)completeStartupAndResumeTasks {
#if APPTENTIVE_DEBUG
	[Apptentive.shared checkSDKConfiguration];

	self.configuration.expiry = [NSDate distantPast];
#endif

	[self updateNetworkingForCurrentNetworkStatus];
}

// This should be called once we might have an active conversation, and perodically after that
- (void)completeHousekeepingTasks {
	[self fetchConfigurationIfNeeded];

	[self.operationQueue addOperationWithBlock:^{
		[self.conversationManager completeHousekeepingTasks];

		[self processQueuedRecords];
	}];
}

- (void)migrateLegacyCoreDataAndTaskQueueForConversation:(ApptentiveConversation *)conversation conversationDirectoryPath:(NSString *)directoryPath {
	ApptentiveAssertNotNil(conversation, @"Trying to migrate nil conversation");
	ApptentiveAssertTrue(conversation.state == ApptentiveConversationStateLegacyPending, @"Trying to migrate conversation that is not a legacy conversation (%@)", NSStringFromApptentiveConversationState(conversation.state));

	if (conversation.state != ApptentiveConversationStateLegacyPending) {
		return;
	}
	
	NSManagedObjectContext *parentContext = self.managedObjectContext;
	ApptentiveAssertNotNil(parentContext, @"Parent context is nil");
	if (parentContext == nil) {
		return;
	}

	NSString *legacyTaskPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"tasks.objects"];
	NSError *error;
	if ([[NSFileManager defaultManager] fileExistsAtPath:legacyTaskPath] && ![[NSFileManager defaultManager] removeItemAtPath:legacyTaskPath error:&error]) {
		ApptentiveLogError(@"Unable to delete migrated tasks: %@", error);
	}

	NSString *newAttachmentPath = [ApptentiveMessageManager attachmentDirectoryPathForConversationDirectory:directoryPath];
	NSString *oldAttachmentPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];

	// Enqueue any unsent messages, events, or survey responses from <= v3.4
	NSManagedObjectContext *migrationContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	migrationContext.parentContext = parentContext;

	[migrationContext performBlockAndWait:^{
		[ApptentiveLegacyMessage enqueueUnsentMessagesInContext:migrationContext forConversation:conversation oldAttachmentPath:oldAttachmentPath newAttachmentPath:newAttachmentPath];
		[ApptentiveLegacyEvent enqueueUnsentEventsInContext:migrationContext forConversation:conversation];
		[ApptentiveLegacySurveyResponse enqueueUnsentSurveyResponsesInContext:migrationContext forConversation:conversation];

		NSError *coreDataError;
		if (![migrationContext save:&coreDataError]) {
			ApptentiveLogError(@"Unable to save migration context: %@", coreDataError);
		}
	}];

	[self processQueuedRecords];
}

- (void)processQueuedRecords {
	ApptentiveAssertOperationQueue(self.operationQueue);

	if (self.state == ApptentiveBackendStatePayloadDatabaseAvailable && self.networkAvailable && self.conversationManager.activeConversation.token != nil) {
		[self.payloadSender createOperationsForQueuedRequestsInContext:self.managedObjectContext];
	}
}

- (void)processConfigurationResponse:(NSDictionary *)configurationResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	ApptentiveAssertOperationQueue(self.operationQueue);

	_configuration = [[ApptentiveAppConfiguration alloc] initWithJSONDictionary:configurationResponse cacheLifetime:cacheLifetime];

	[self saveConfiguration];
}

- (BOOL)saveConfiguration {
	@synchronized(self.configuration) {
		return [NSKeyedArchiver archiveRootObject:self.configuration toFile:[self configurationPath]];
	}
}

- (void)updateNetworkingForCurrentNetworkStatus {
	BOOL networkWasAvailable = self.networkAvailable;

	ApptentiveNetworkStatus status = [self.reachability currentNetworkStatus];
	_networkAvailable = (status != ApptentiveNetworkNotReachable);

	if (self.networkAvailable != networkWasAvailable) {
		if (self.networkAvailable) {
			[self.client resetBackoffDelay];
			[self.payloadSender resetBackoffDelay];

			[self completeHousekeepingTasks];
		} else {
			[self.payloadSender cancelNetworkOperations];
		}
	}
}

- (void)addLaunchMetric {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)addExitMetric {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

#pragma mark Message Center

- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController {
	return [self presentMessageCenterFromViewController:viewController withCustomData:nil];
}

- (BOOL)presentMessageCenterFromViewController:(nullable UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData {
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
		// Only present Message Center UI in Active state.
		return NO;
	}

	self.currentCustomData = customData;

	if (viewController.presentedViewController) {
		ApptentiveLogError(@"Attempting to present Apptentive Message Center from View Controller that is already presenting a modal view controller");
		return NO;
	}

	if (self.presentedMessageCenterViewController != nil) {
		ApptentiveLogInfo(@"Apptentive message center controller already shown.");
		return NO;
	}

	BOOL didShowMessageCenter = [[ApptentiveInteraction apptentiveAppInteraction] engage:ApptentiveEngagementMessageCenterEvent fromViewController:viewController];

	if (!didShowMessageCenter) {
		ApptentiveNavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"NoPayloadNavigation"];

		if (viewController != nil) {
			[viewController presentViewController:navigationController animated:YES completion:nil];
		} else {
			[navigationController presentAnimated:YES completion:nil];
		}
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
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation checkForDeviceDiffs];
}

- (void)schedulePersonUpdate {
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation checkForPersonDiffs];
}

#pragma mark Message Polling

- (NSUInteger)unreadMessageCount {
	return self.messageManager.unreadCount;
}

- (void)updateMessageCheckingTimer {
	ApptentiveAssertOperationQueue(self.operationQueue);
	if (self.messageManager != nil) {
		if (self.networkAvailable) {
			if (self.messageCenterInForeground) {
				self.messageManager.pollingInterval = self.configuration.messageCenter.foregroundPollingInterval;
			} else {
				self.messageManager.pollingInterval = self.configuration.messageCenter.backgroundPollingInterval;
			}
		} else {
			[self.messageManager stopPolling];
		}
	}
}

- (void)messageCenterEnteredForeground {
	[self.operationQueue addOperationWithBlock:^{
        _messageCenterInForeground = YES;
        
        ApptentiveAssertNotNil(self.messageManager, @"Message manager is nil");
        [self.messageManager checkForMessages];
        
        [self updateMessageCheckingTimer];
	}];
}

- (void)messageCenterLeftForeground {
	[self.operationQueue addOperationWithBlock:^{
		_messageCenterInForeground = NO;

		[self updateMessageCheckingTimer];

		if (self.presentedMessageCenterViewController) {
			self.presentedMessageCenterViewController = nil;
		}
	}];
}

#pragma mark - Conversation manager delegate

- (void)conversationManager:(ApptentiveConversationManager *)manager conversationDidChangeState:(ApptentiveConversation *)conversation {
	// Anonymous pending conversations will not yet have a token, so we can't finish starting up yet in that case.
	if (conversation.state != ApptentiveConversationStateAnonymousPending &&
		conversation.state != ApptentiveConversationStateLegacyPending) {

		if (conversation.state == ApptentiveConversationStateAnonymous) {
			[self.payloadSender updateQueuedRequestsInContext:self.managedObjectContext withConversation:conversation];

			[self completeHousekeepingTasks];
		}
	}

	if (conversation.state == ApptentiveConversationStateAnonymous ||
		conversation.state == ApptentiveConversationStateLoggedIn) {
		if (Apptentive.shared.didAccessStyleSheet) {
			[conversation didOverrideStyles];
		}
	}
}

#pragma mark - Authentication

- (void)authenticationDidFailNotification:(NSNotification *)notification {
	[self.operationQueue addOperationWithBlock:^{
		ApptentiveConversationState conversationState = self.conversationManager.activeConversation.state;
        if (conversationState == ApptentiveConversationStateLoggedIn && self.authenticationFailureCallback) {
            NSString *conversationIdentifier = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyConversationIdentifier);
            
            if (![conversationIdentifier isEqualToString:self.conversationManager.activeConversation.identifier]) {
                ApptentiveLogDebug(@"Conversation identifier mismatch");
                return;
            }
            
            NSString *errorType = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyErrorType);
            NSString *errorMessage = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyErrorMessage);
            ApptentiveAuthenticationFailureReason reason = parseAuthenticationFailureReason(errorType);
            self.authenticationFailureCallback(reason, errorMessage);
		} else if (conversationState == ApptentiveConversationStateAnonymousPending || conversationState == ApptentiveConversationStateLegacyPending) {
			ApptentiveAssertFail(@"Authentication failure when creating conversation. Please double-check your Apptentive App Key and Apptentive App Signature.");
		}
	}];
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

- (NSString *)configurationPath {
	return [self.supportDirectoryPath stringByAppendingPathComponent:@"configuration-v1.archive"];
}

#pragma mark -
#pragma mark Properties

- (ApptentiveMessageManager *)messageManager {
	return self.conversationManager.messageManager;
}

@end

NS_ASSUME_NONNULL_END
