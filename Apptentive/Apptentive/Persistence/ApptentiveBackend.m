//
//  ApptentiveBackend.m
//  Apptentive
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveConfigurationRequest.h"
#import "ApptentiveDataManager.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveLog.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveMessageManager.h"
#import "ApptentivePayloadSender.h"
#import "ApptentivePerson.h"
#import "ApptentiveReachability.h"
#import "ApptentiveSDK.h"
#import "ApptentiveSafeCollections.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import "Apptentive_Private.h"
#import "ApptentiveDispatchQueue.h"
#import "ApptentiveRetryPolicy.h"

#import "ApptentiveLegacyEvent.h"
#import "ApptentiveLegacyFileAttachment.h"
#import "ApptentiveLegacyMessage.h"
#import "ApptentiveLegacySurveyResponse.h"

#import "ApptentiveApptimize.h"

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

@property (strong, nonatomic) CTTelephonyNetworkInfo *telephonyNetworkInfo;

@property (strong, nonatomic) NSTimer *messageRetrievalTimer;
@property (strong, nonatomic) ApptentiveDataManager *dataManager;
@property (readonly, nonatomic) ApptentiveMessageManager *messageManager;

@property (readonly, nonatomic, getter=isMessageCenterInForeground) BOOL messageCenterInForeground;

@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (strong, nonatomic) ApptentiveReachability *reachability;

@property (assign, nonatomic, getter=isForeground) BOOL foreground;

@end


@implementation ApptentiveBackend

@synthesize supportDirectoryPath = _supportDirectoryPath;

- (instancetype)initWithApptentiveKey:(NSString *)apptentiveKey signature:(NSString *)signature baseURL:(NSURL *)baseURL storagePath:(NSString *)storagePath operationQueue:(ApptentiveDispatchQueue *)operationQueue {
	self = [super init];

	if (self) {
		_apptentiveKey = apptentiveKey;
		_apptentiveSignature = signature;
		_baseURL = baseURL;
		_storagePath = storagePath;

		_operationQueue = operationQueue;
		_supportDirectoryPath = [[ApptentiveUtilities applicationSupportPath] stringByAppendingPathComponent:storagePath];

		if ([UIApplication sharedApplication] != nil && ![UIApplication sharedApplication].isProtectedDataAvailable) {
			_operationQueue.suspended = YES;

			__weak ApptentiveBackend *weakSelf = self;
			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable
															  object:nil
															   queue:[NSOperationQueue mainQueue]
														  usingBlock:^(NSNotification *_Nonnull note) {
															ApptentiveBackend *strongSelf = weakSelf;
															if (strongSelf) {
																strongSelf.operationQueue.suspended = NO;
															}
														  }];
		}

		_reachability = [[ApptentiveReachability alloc] initWithHostname:self.baseURL.host];
		_foreground = UIApplication.sharedApplication.applicationState != UIApplicationStateBackground;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ApptentiveReachabilityStatusChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apptentiveInteractionsDidUpdateNotification:) name:ApptentiveInteractionsDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticationDidFailNotification:) name:ApptentiveAuthenticationDidFailNotification object:nil];

		[self updateAndMonitorDeviceValues];

		[_operationQueue dispatchAsync:^{
		  [self createSupportDirectoryIfNeeded];

		  [self setUpCoreData];

		  [self loadConfiguration];
			
		  [self maybeGetAdvertisingIdentifier];
		  [self tryInitializeApptimizeSDK];

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
	ApptentiveAssertMainQueue
	[ApptentiveDevice getPermanentDeviceValues];

	__weak ApptentiveBackend *weakSelf = self;
	if ([CTTelephonyNetworkInfo class]) {
		_telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
		ApptentiveDevice.carrierName = _telephonyNetworkInfo.subscriberCellularProvider.carrierName;

		_telephonyNetworkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier *_Nonnull carrier) {
		  ApptentiveBackend *strongSelf = weakSelf;
		  ApptentiveDevice.carrierName = carrier.carrierName;
		  ApptentiveLogDebug(@"Carrier changed to %@. Updating device.", ApptentiveDevice.carrierName);
		  [strongSelf.operationQueue dispatchAsync:^{
			[strongSelf scheduleDeviceUpdate]; // Must happen on our queue
		  }];
		};
	}

	ApptentiveDevice.contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
	[NSNotificationCenter.defaultCenter addObserverForName:UIContentSizeCategoryDidChangeNotification
													object:nil
													 queue:[NSOperationQueue mainQueue]
												usingBlock:^(NSNotification *_Nonnull note) {
												  ApptentiveBackend *strongSelf = weakSelf;
												  ApptentiveDevice.contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory; // Must happen on main queue
												  ApptentiveLogDebug(@"Content size category changed to %@. Updating device.", ApptentiveDevice.contentSizeCategory);
												  [strongSelf.operationQueue dispatchAsync:^{
													[strongSelf scheduleDeviceUpdate]; // Must happen on our queue
												  }];
												}];

	[[NSNotificationCenter defaultCenter] addObserverForName:NSSystemTimeZoneDidChangeNotification
													  object:nil
													   queue:[NSOperationQueue mainQueue]
												  usingBlock:^(NSNotification *_Nonnull note) {
													ApptentiveLogDebug(@"System time zone changed to %@. Updating device.", NSTimeZone.systemTimeZone);
													ApptentiveBackend *strongSelf = weakSelf;
													  [strongSelf.operationQueue dispatchAsync:^{
														  [strongSelf scheduleDeviceUpdate];
													  }];
													
												  }];
}

#pragma mark Notification Handling

- (void)networkStatusChanged:(NSNotification *)notification {
	[self.operationQueue dispatchAsync:^{
		[self updateNetworkingForCurrentNetworkStatus];
	}];
}

- (void)applicationWillTerminateNotification:(NSNotification *)notification {
	[self.operationQueue dispatchAsync:^{
		if (self.foreground) {
			[self addExitMetric];
			[self.conversationManager.activeConversation endSession];
		}
	}];

	[self shutDown];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification {
	[self.operationQueue dispatchAsync:^{
		self->_foreground = NO;
		[self addExitMetric];
		[self.conversationManager.activeConversation endSession];
	}];

	[self shutDown];
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification {
	[self.operationQueue dispatchAsync:^{
		self->_foreground = YES;
		[self resume];
		[self.conversationManager.activeConversation startSession];
		[self addLaunchMetric];
		[self maybeGetAdvertisingIdentifier];
	}];
}

- (void)apptentiveInteractionsDidUpdateNotification:(NSNotification *)notification {
	[self.operationQueue dispatchAsync:^{
	  [self updateMessageCheckingTimer];
	}];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

#pragma mark - As-needed tasks

- (void)fetchConfigurationIfNeeded {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveConversation *conversation = self.conversationManager.activeConversation;

	if (self.configurationOperation != nil || conversation.identifier == nil || !self.networkAvailable || !self.foreground || [self.configuration.expiry timeIntervalSinceNow] > 0) {
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
	ApptentiveAssertOperationQueue(self.operationQueue);
	if (![[NSFileManager defaultManager] fileExistsAtPath:self.supportDirectoryPath]) {
		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:self.supportDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(ApptentiveLogTagStorage, @"Unable to create storage path %@ (%@).", self.supportDirectoryPath, error);
		}
	}
}

#pragma mark - Lifecycle

- (void)startUp {
	ApptentiveAssertOperationQueue(self.operationQueue);

	_client = [[ApptentiveClient alloc] initWithBaseURL:self.baseURL apptentiveKey:self.apptentiveKey apptentiveSignature:self.apptentiveSignature delegateQueue:self.operationQueue];
	_client.paused = !self.networkAvailable;

	_conversationManager = [[ApptentiveConversationManager alloc] initWithStoragePath:self.supportDirectoryPath operationQueue:self.operationQueue client:self.client managedObjectContext:self.managedObjectContext];
	self.conversationManager.delegate = self;

	_payloadSender = [[ApptentivePayloadSender alloc] initWithBaseURL:self.baseURL apptentiveKey:self.apptentiveKey apptentiveSignature:self.apptentiveSignature managedObjectContext:self.managedObjectContext delegateQueue:self.operationQueue];
	_payloadSender.paused = !self.networkAvailable;

	[self.conversationManager loadActiveConversation];

	[self completeStartupAndResumeTasks];

	if (self.foreground) {
		[self.conversationManager.activeConversation startSession];
		[self addLaunchMetric];
	} else {
		ApptentiveLogDebug(@"Skip engaging launch event because app started in the background.");
	}
}

// This is called when we're about to enter the background
- (void)shutDown {
	ApptentiveLogVerbose(@"Shutting down backend.");

	// Asynchronous tasks off the main thread will not be given a chance to complete automatically.
	// We create a background task to clear out our operation queue and the payload sender queue.
	self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"Wind Down Backend"
																				 expirationHandler:^{
																				   ApptentiveLogWarning(@"Background task (%ld) did not complete in time.", (unsigned long)self.backgroundTaskIdentifier);
																				   [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
																				 }];

	// Here, we cancel any ongoing network operations in the payload sender.
	[self.payloadSender cancelNetworkOperations];

	// Create an operation to end the background task.
	[self.operationQueue dispatchAsync:^{
		[self.conversationManager pause];

		// After all background operations are finished, wait for anything on the payload sender's network queue to finish before telling the OS we're done.
		[self.payloadSender.networkQueue addOperationWithBlock:^{
			ApptentiveLogDebug(@"All background operations finished. Exiting.");
			[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
		}];
	}];
}

// This is called on a warm launch
- (void)resume {
	ApptentiveAssertOperationQueue(self.operationQueue);

	[self completeStartupAndResumeTasks];

	[self completeHousekeepingTasks];
}

// Note: must be called on main thread
- (void)setUpCoreData {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveLogVerbose(ApptentiveLogTagStorage, @"Setting up data manager.");
	self.dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[ApptentiveUtilities resourceBundle] storagePath:[self supportDirectoryPath]];
	if (![self.dataManager setupAndVerify]) {
		ApptentiveLogError(ApptentiveLogTagStorage, @"Unable to setup and verify data manager.");
	} else if (![self.dataManager persistentStoreCoordinator]) {
		ApptentiveLogError(ApptentiveLogTagStorage, @"There was a problem setting up the persistent store coordinator.");
	}
}

- (void)loadConfiguration {
	ApptentiveAssertOperationQueue(self.operationQueue);
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
	ApptentiveAssertOperationQueue(self.operationQueue);
#if APPTENTIVE_DEBUG
	[Apptentive.shared checkSDKConfiguration];

	self.configuration.expiry = [NSDate distantPast];
#endif

	[self updateNetworkingForCurrentNetworkStatus];
}

// This should be called once we might have an active conversation, and perodically after that
- (void)completeHousekeepingTasks {
	ApptentiveAssertOperationQueue(self.operationQueue);

	[self fetchConfigurationIfNeeded];

	[self.conversationManager completeHousekeepingTasks];

	[self processQueuedRecords];
}

- (void)migrateLegacyCoreDataAndTaskQueueForConversation:(ApptentiveConversation *)conversation conversationDirectoryPath:(NSString *)directoryPath {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveAssertNotNil(conversation, @"Trying to migrate nil conversation");
	ApptentiveAssertTrue(conversation.state == ApptentiveConversationStateLegacyPending, @"Trying to migrate conversation that is not a legacy conversation (%@)", NSStringFromApptentiveConversationState(conversation.state));

	if (conversation.state != ApptentiveConversationStateLegacyPending) {
		return;
	}

	ApptentiveAssertNotNil(self.managedObjectContext, @"Managed object context is nil");
	if (self.managedObjectContext == nil) {
		return;
	}

	NSString *legacyTaskPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"tasks.objects"];
	NSError *error;
	if ([[NSFileManager defaultManager] fileExistsAtPath:legacyTaskPath] && ![[NSFileManager defaultManager] removeItemAtPath:legacyTaskPath error:&error]) {
		ApptentiveLogError(@"Unable to delete migrated tasks: %@", error);
	}

	NSString *newAttachmentPath = [ApptentiveMessageManager attachmentDirectoryPathForConversationDirectory:directoryPath];
	NSString *oldAttachmentPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"attachments"];

	[self.managedObjectContext performBlockAndWait:^{
	  [ApptentiveLegacyMessage enqueueUnsentMessagesInContext:self.managedObjectContext forConversation:conversation oldAttachmentPath:oldAttachmentPath newAttachmentPath:newAttachmentPath];
	  [ApptentiveLegacyEvent enqueueUnsentEventsInContext:self.managedObjectContext forConversation:conversation];
	  [ApptentiveLegacySurveyResponse enqueueUnsentSurveyResponsesInContext:self.managedObjectContext forConversation:conversation];

	  NSError *coreDataError;
	  if (![self.managedObjectContext save:&coreDataError]) {
		  ApptentiveLogError(@"Unable to save core data migration context (%@).", coreDataError);
	  }
	}];

	[self processQueuedRecords];
}

- (void)processQueuedRecords {
	ApptentiveAssertOperationQueue(self.operationQueue);

	if (self.foreground && self.networkAvailable && self.conversationManager.activeConversation.token != nil) {
		[self.payloadSender createOperationsForQueuedRequestsInContext:self.managedObjectContext];
	}
}

- (void)processConfigurationResponse:(NSDictionary *)configurationResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	ApptentiveAssertOperationQueue(self.operationQueue);

	_configuration = [[ApptentiveAppConfiguration alloc] initWithJSONDictionary:configurationResponse cacheLifetime:cacheLifetime];
	
	[self saveConfiguration];

	[self maybeGetAdvertisingIdentifier];
	[self tryUpdateApptimizeData];
}

- (BOOL)saveConfiguration {
	ApptentiveAssertOperationQueue(self.operationQueue);
	return [NSKeyedArchiver archiveRootObject:self.configuration toFile:[self configurationPath]];
}

- (void)updateNetworkingForCurrentNetworkStatus {
	ApptentiveAssertOperationQueue(self.operationQueue);
	BOOL networkWasAvailable = self.networkAvailable;

	ApptentiveNetworkStatus status = [self.reachability currentNetworkStatus];
	_networkAvailable = (status != ApptentiveNetworkNotReachable);

	if (self.networkAvailable != networkWasAvailable) {
		if (self.networkAvailable) {
			[self.client.retryPolicy resetRetryDelay];
			[self.payloadSender.retryPolicy resetRetryDelay];
			self.client.paused = NO;
			self.payloadSender.paused = NO;

			[self completeHousekeepingTasks];
		} else {
			[self.payloadSender cancelNetworkOperations];
			self.client.paused = YES;
			self.payloadSender.paused = YES;
		}
	}
}

- (void)addLaunchMetric {
	ApptentiveAssertOperationQueue(self.operationQueue);

	[self engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)addExitMetric {
	ApptentiveAssertOperationQueue(self.operationQueue);

	[self engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

#pragma mark Message Center

- (void)presentMessageCenterFromViewController:(nullable UIViewController *)viewController completion:(void (^ _Nullable)(BOOL))completion {
	[self presentMessageCenterFromViewController:viewController withCustomData:nil completion:completion];
}

- (void)presentMessageCenterFromViewController:(nullable UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData completion:(void (^ _Nullable)(BOOL))completion {
	
	if (![NSThread isMainThread]) {
		[self presentMessageCenterFromViewController:viewController withCustomData:customData completion:completion];
		return;
	}
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
		// Only present Message Center UI in Active state.
		if (completion) {
			completion(NO);
		}
		return;
	}

	self.currentCustomData = customData;

	if (viewController.presentedViewController) {
		ApptentiveLogError(ApptentiveLogTagInteractions, @"Attempting to present Apptentive Message Center from View Controller that is already presenting a modal view controller.");
		if (completion) {
			completion(NO);
		}
		return;
	}

	if (self.presentedMessageCenterViewController != nil) {
		ApptentiveLogInfo(ApptentiveLogTagInteractions, @"Apptentive message center controller already shown.");
		if (completion) {
			completion(NO);
		}
		return;
	}

	[self engage:ApptentiveEngagementMessageCenterEvent fromInteraction:[ApptentiveInteraction apptentiveAppInteraction] fromViewController:viewController userInfo:nil customData:nil extendedData:nil completion:^(BOOL didShowMessageCenter) {
		dispatch_sync(dispatch_get_main_queue(), ^{
			if (!didShowMessageCenter) {
				ApptentiveNavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"NoPayloadNavigation"];
				
				if (viewController != nil) {
					[viewController presentViewController:navigationController animated:YES completion:nil];
				} else {
					[navigationController presentAnimated:YES completion:nil];
				}
			}
			
			if (completion) {
				completion(didShowMessageCenter);
			}
		});
	}];
}

- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(void (^)(void))completion {
	ApptentiveAssertMainQueue
	self.currentCustomData = nil;

	if (self.presentedMessageCenterViewController != nil) {
		UIViewController *vc = [self.presentedMessageCenterViewController presentingViewController];
		[vc dismissViewControllerAnimated:YES
							   completion:^{
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

// TODO: get rid of this function and listen to data changes instead
- (void)scheduleDeviceUpdate {
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation checkForDeviceDiffs];
}

// TODO: get rid of this function and listen to data changes instead
- (void)schedulePersonUpdate {
	ApptentiveAssertOperationQueue(self.operationQueue);
	[self.conversationManager.activeConversation checkForPersonDiffs];
}

#pragma mark Message Polling

- (void)updateMessageCheckingTimer {
	ApptentiveAssertOperationQueue(self.operationQueue);
	if (self.messageManager != nil) {
		if (self.networkAvailable && self.foreground) {
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
	[self.operationQueue dispatchAsync:^{
	  self->_messageCenterInForeground = YES;

	  ApptentiveAssertNotNil(self.messageManager, @"Message manager is nil");
	  [self.messageManager checkForMessages];

	  [self updateMessageCheckingTimer];
	}];
}

- (void)messageCenterLeftForeground {
	[self.operationQueue dispatchAsync:^{
	  self->_messageCenterInForeground = NO;

	  [self updateMessageCheckingTimer];

	  if (self.presentedMessageCenterViewController) {
		  self.presentedMessageCenterViewController = nil;
	  }
	}];
}

#pragma mark - Person name/email

- (void)setPersonName:(NSString *)personName {
	_personName = personName;

	[self.operationQueue dispatchAsync:^{
		self.conversationManager.activeConversation.person.name = personName;
		[self schedulePersonUpdate];
	}];
}

- (void)setPersonEmailAddress:(NSString *)personEmailAddress {
	_personEmailAddress = personEmailAddress;

	[self.operationQueue dispatchAsync:^{
		self.conversationManager.activeConversation.person.emailAddress = personEmailAddress;
		[self schedulePersonUpdate];
	}];
}

- (void)setMParticleId:(NSString *)mParticleId {
	[self.operationQueue dispatchAsync:^{
		if (self.conversationManager.activeConversation == nil) {
			ApptentiveLogWarning(ApptentiveLogTagConversation, @"Cannot update mParticle ID because the active conversation is nil");
			return;
		}

		self.conversationManager.activeConversation.person.mParticleId = mParticleId;
		[self schedulePersonUpdate];
	}];
}

#pragma mark - Conversation manager delegate

- (void)conversationManager:(ApptentiveConversationManager *)manager conversationDidChangeState:(ApptentiveConversation *)conversation {
	ApptentiveAssertOperationQueue(self.operationQueue);

	_personName = conversation.person.name;
	_personEmailAddress = conversation.person.emailAddress;

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
	ApptentiveAssertOperationQueue(self.operationQueue);

	ApptentiveConversationState conversationState = self.conversationManager.activeConversation.state;
	if (conversationState == ApptentiveConversationStateLoggedIn && self.authenticationFailureCallback) {
		NSString *conversationIdentifier = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyConversationIdentifier);

		if (![conversationIdentifier isEqualToString:self.conversationManager.activeConversation.identifier]) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"The identifier for the newly logged-in conversation did not match the active conversation.");
			return;
		}

		NSString *errorType = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyErrorType);
		NSString *errorMessage = ApptentiveDictionaryGetString(notification.userInfo, ApptentiveAuthenticationDidFailNotificationKeyErrorMessage);
		ApptentiveAuthenticationFailureReason reason = parseAuthenticationFailureReason(errorType);
		self.authenticationFailureCallback(reason, errorMessage);
	} else if (conversationState == ApptentiveConversationStateAnonymousPending || conversationState == ApptentiveConversationStateLegacyPending) {
		ApptentiveAssertFail(@"Authentication failure when creating conversation. Please double-check your Apptentive App Key and Apptentive App Signature.");
	}
}

#pragma mark -
#pragma mark Apptimize SDK

- (void)tryUpdateApptimizeData {
	if (!self.configuration.collectApptimizeData) {
		return;
	}
	
	ApptentiveConversation *activeConversation = self.conversationManager.activeConversation;
	if (activeConversation == nil) {
		ApptentiveLogWarning(ApptentiveLogTagApptimize, @"Unable to update Apptimize data: no active conversation");
		return;
	}
	
	if (![ApptentiveApptimize isApptimizeSDKAvailable]) {
		ApptentiveLogWarning(ApptentiveLogTagApptimize, @"Unable to update Apptimize data: SDK is not detected");
		return;
	}
	
	if (![ApptentiveApptimize isSupportedLibraryVersion]) {
		ApptentiveLogWarning(ApptentiveLogTagApptimize, @"Unable to update Apptimize data: unsupported library version '%@'", [ApptentiveApptimize libraryVersion]);
		return;
	}
	
	NSDictionary<NSString *, ApptentiveApptimizeTestInfo*> * experiments = [ApptentiveApptimize testInfo];
	if (experiments.count == 0) {
		ApptentiveLogDebug(ApptentiveLogTagApptimize, @"Unable to update Apptimize data: no experiments");
		return;
	}
	
	for (NSString *experimentName in experiments) {
		ApptentiveApptimizeTestInfo *experiment = experiments[experimentName];
		if (experiment == nil) {
			continue;
		}
		
		[self conversation:activeConversation addApptimizeExperimentToDeviceData:experiment];
	}
	
	[self scheduleDeviceUpdate];
}

- (void)conversation:(ApptentiveConversation *)conversation addApptimizeExperimentToDeviceData:(ApptentiveApptimizeTestInfo *)experiment {
	ApptentiveAssertNotNil(conversation, @"Attempted to add Apptimize experiment to a nil conversation");
	if (conversation == nil) {
		return;
	}
	
	NSString *testName = experiment.testName;
	NSString *variantName = experiment.enrolledVariantName;
	
	NSString *participationState = experiment.userHasParticipated ? @"participated" : @"enrolled";
	
	NSString *key = [NSString stringWithFormat:@"Apptimize: %@ %@", testName, participationState];
	[conversation.device addCustomString:variantName withKey:key];
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
		ApptentiveLogError(ApptentiveLogTagStorage, @"Failed to create support directory %@ (%@).", newPath, error);
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
	ApptentiveAssertOperationQueue(self.operationQueue);
	return self.conversationManager.messageManager;
}

#pragma mark -
#pragma mark Advertising Identifier

- (void)maybeGetAdvertisingIdentifier {
	ApptentiveAssertOperationQueue(self.operationQueue);
	
	if (self.configuration.collectAdvertisingIdentifier) {
		[ApptentiveDevice getAdvertisingIdentifier];
		[self scheduleDeviceUpdate];
	}
}

#pragma mark -
#pragma mark Apptimize SDK

- (void)tryInitializeApptimizeSDK {
	ApptentiveAssertOperationQueue(self.operationQueue);
	ApptentiveAssertNotNil(self.configuration, @"Missing configuration");
	
	if (!self.configuration.collectApptimizeData) {
		return;
	}
	
	if (![ApptentiveApptimize isApptimizeSDKAvailable]) {
		ApptentiveLogWarning(ApptentiveLogTagApptimize, @"Unable to initialize Apptimize SDK support: SDK integration not found");
		return;
	}
	
	if (![ApptentiveApptimize isSupportedLibraryVersion]) {
		ApptentiveLogWarning(ApptentiveLogTagApptimize, @"Unable to update Apptimize data: unsupported library version '%@'", [ApptentiveApptimize libraryVersion]);
		return;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(experimentParticipationNotification:)
												 name:ApptentiveApptimizeTestRunNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(testsProcessedNotification:)
												 name:ApptimizeTestsProcessedNotification
											   object:nil];
	
	[self tryUpdateApptimizeData];
}

- (void)experimentParticipationNotification:(NSNotification*)notification {
	ApptentiveConversation *conversation = self.conversationManager.activeConversation;
	
	// Get the relevant participation info
	NSString *experimentName = notification.userInfo[ApptentiveApptimizeTestNameUserInfoKey];
	if (experimentName.length == 0) {
		ApptentiveLogVerbose(ApptentiveLogTagApptimize, @"Missing experiment name");
		return;
	}
	
	NSString *variantName = notification.userInfo[ApptentiveApptimizeVariantNameUserInfoKey];
	if (variantName.length == 0) {
		ApptentiveLogVerbose(ApptentiveLogTagApptimize, @"Missing variant name for experiment '%@'", experimentName);
		return;
	}
	
	if (conversation == nil) {
		ApptentiveLogVerbose(ApptentiveLogTagApptimize, @"Ignoring experiment '%@-%@': no active conversation", experimentName, variantName);
		return;
	}
	
	ApptentiveApptimizeTestInfo *experiment = [ApptentiveApptimize testInfo][experimentName];
	if (!experiment) {
		// Shouldn't happen but just in case
		return;
	}
	
	[self conversation:conversation addApptimizeExperimentToDeviceData:experiment];
	[self scheduleDeviceUpdate];
}

- (void)testsProcessedNotification:(NSNotification*)notification {
	[self tryUpdateApptimizeData];
}

@end

NS_ASSUME_NONNULL_END
