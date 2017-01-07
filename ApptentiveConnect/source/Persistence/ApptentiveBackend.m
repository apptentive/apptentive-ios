//
//  ApptentiveBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveDataManager.h"
#import "ApptentiveMetrics.h"
#import "ApptentiveReachability.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveLog.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveFileAttachment.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveVersion.h"

typedef NS_ENUM(NSInteger, ATBackendState) {
	ATBackendStateStarting,
	ATBackendStateWaitingForDataProtectionUnlock,
	ATBackendStateReady
};

NSString *const ATBackendBecameReadyNotification = @"ATBackendBecameReadyNotification";
NSString *const ATConfigurationPreferencesChangedNotification = @"ATConfigurationPreferencesChangedNotification";

NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";
NSString *const ATLegacyUUIDPreferenceKey = @"ATLegacyUUIDPreferenceKey";
NSString *const ATInfoDistributionKey = @"ATInfoDistributionKey";
NSString *const ATInfoDistributionVersionKey = @"ATInfoDistributionVersionKey";


@interface ApptentiveBackend ()
- (void)updateConfigurationIfNeeded;

@property (readonly, nonatomic, getter=isMessageCenterInForeground) BOOL messageCenterInForeground;

@property (copy, nonatomic) void (^backgroundFetchBlock)(UIBackgroundFetchResult);

@end


@interface ApptentiveBackend ()
- (void)updateWorking;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)startMonitoringUnreadMessages;

@property (strong, nonatomic) UIViewController *presentingViewController;
@property (assign, nonatomic) BOOL working;
@property (strong, nonatomic) NSTimer *messageRetrievalTimer;
@property (copy, nonatomic) NSString *cachedDeviceUUID;
@property (assign, nonatomic) ATBackendState state;
@property (strong, nonatomic) ApptentiveDataManager *dataManager;
@property (strong, nonatomic) NSFetchedResultsController *unreadCountController;
@property (assign, nonatomic) NSUInteger previousUnreadCount;
@property (assign, nonatomic) BOOL shouldStopWorking;
@property (assign, nonatomic) BOOL networkAvailable;

@property (strong, nonatomic) ApptentiveRequestOperation *conversationOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *configurationOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *messageOperation;
@property (strong, nonatomic) ApptentiveRequestOperation *manifestOperation;

@end


@implementation ApptentiveBackend

@synthesize supportDirectoryPath = _supportDirectoryPath;

+ (UIImage *)imageNamed:(NSString *)name {
	return [UIImage imageNamed:name inBundle:[Apptentive resourceBundle] compatibleWithTraitCollection:nil];
}

- (instancetype)initWithAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL {
	self = [super init];

	if (self) {
		_state = ATBackendStateStarting;
		_queue = [[NSOperationQueue alloc] init];

		if ([UIApplication sharedApplication] != nil && ![UIApplication sharedApplication].isProtectedDataAvailable) {
			_queue.suspended = YES;
			_state = ATBackendStateWaitingForDataProtectionUnlock;

			[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
				self.queue.suspended = NO;
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

		NSBlockOperation *startupOperation = [NSBlockOperation blockOperationWithBlock:^{
			// Session
			if ([[NSFileManager defaultManager] fileExistsAtPath:[self sessionPath]]) {
				self->_session = [NSKeyedUnarchiver unarchiveObjectWithFile:[self sessionPath]];
			} else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInstallDateKey"]) {
				self->_session = [[ApptentiveSession alloc] initAndMigrate];
				[self saveSession];
				// TODO: delete migrated data
			} else {
				self->_session = [[ApptentiveSession alloc] initWithAPIKey:APIKey];
			}

			self->_session.delegate = self;

			// Configuration
			if ([[NSFileManager defaultManager] fileExistsAtPath:[self configurationPath]]) {
				self->_configuration = [NSKeyedUnarchiver unarchiveObjectWithFile:[self configurationPath]];
			} else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ATConfigurationSDKVersionKey"]) {
				self->_configuration = [[ApptentiveAppConfiguration alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
				[self saveConfiguration];
				// TODO: delete migrated data
			} else {
				self->_configuration = [[ApptentiveAppConfiguration alloc] init];
			}

			// Interaction Manifest
			if ([[NSFileManager defaultManager] fileExistsAtPath:[self manifestPath]]) {
				self->_manifest = [NSKeyedUnarchiver unarchiveObjectWithFile:[self manifestPath]];
			} else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInteractionsSDKVersionKey"]) {
				self->_manifest = [[ApptentiveEngagementManifest alloc] initWithCachePath:[self supportDirectoryPath] userDefaults:[NSUserDefaults standardUserDefaults]];
				[self saveManifest];
				// TODO: delete migrated data
			} else {
				self->_manifest = [[ApptentiveEngagementManifest alloc] init];
			}

			NSString *token = self.session.token ?: self.session.APIKey;
			self->_networkQueue = [[ApptentiveNetworkQueue alloc] initWithBaseURL:baseURL token:token SDKVersion:self.session.SDK.version.versionString platform:@"iOS"];

			if (self.session.token == nil) {
				[self createConversation];
			}

			[self updateConfigurationIfNeeded];
			[self updateEngagementManifestIfNeeded];

			dispatch_sync(dispatch_get_main_queue(), ^{
				ApptentiveLogDebug(@"Setting up data manager");
				self.dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:[Apptentive resourceBundle] storagePath:[self supportDirectoryPath]];
				if (![self.dataManager setupAndVerify]) {
					ApptentiveLogError(@"Unable to setup and verify data manager.");
				} else if (![self.dataManager persistentStoreCoordinator]) {
					ApptentiveLogError(@"There was a problem setting up the persistent store coordinator!");
				}
			});

			// Run this once we have a token and core data
			NSBlockOperation *becomeReadyOperation = [NSBlockOperation blockOperationWithBlock:^{
				self->_serialQueue = [[ApptentiveSerialNetworkQueue alloc] initWithBaseURL:baseURL token:self.session.token SDKVersion:self.session.SDK.version.versionString platform:@"iOS" parentManagedObjectContext:self.managedObjectContext];

				[self.serialQueue addObserver:self forKeyPath:@"messageSendProgress" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
				[self.serialQueue addObserver:self forKeyPath:@"messageTaskCount" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];

				[self.session checkForDiffs];

				[ApptentiveMetrics sharedMetrics];
				[ApptentiveReachability sharedReachability];

				[self startMonitoringUnreadMessages];

				self.state = ATBackendStateReady;
				dispatch_async(dispatch_get_main_queue(), ^{
					[[NSNotificationCenter defaultCenter] postNotificationName:ATBackendBecameReadyNotification object:nil];
				});

				[self networkStatusChanged:nil];

				[self processQueuedRecords];

				// Append extensions to attachments that are missing them
				[ApptentiveFileAttachment addMissingExtensions];
			}];

			if (self.conversationOperation) {
				[becomeReadyOperation addDependency:self.conversationOperation];
			}

			[self.queue addOperation:becomeReadyOperation];
		}];

		[_queue addOperation:startupOperation];
	}

	return self;
}

- (void)dealloc {
	[self.messageRetrievalTimer invalidate];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	@try {
		[self.serialQueue removeObserver:self forKeyPath:@"messageTaskCount"];
		[self.serialQueue removeObserver:self forKeyPath:@"messageSendProgress"];
	} @catch (NSException *_) {}
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
#if APPTENTIVE_DEBUG
			[Apptentive.shared checkSDKConfiguration];
			self.configuration.expiry = [NSDate distantPast];
			self.manifest.expiry = [NSDate distantPast];
#endif
			[self.session checkForDiffs];

			[self updateConfigurationIfNeeded];
			[self updateEngagementManifestIfNeeded];
			[self checkForMessages];
		} else {
			[self saveSession];

			[self.networkQueue cancelAllOperations];
			[self.serialQueue cancelAllOperations];
		}

		[self updateMessageCheckingTimer];
	}
}

- (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
}

- (NSString *)deviceUUID {
	return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

- (NSString *)appName {
	NSString *displayName = nil;

	NSArray *appNameKeys = [NSArray arrayWithObjects:@"CFBundleDisplayName", (NSString *)kCFBundleNameKey, nil];
	NSMutableArray *infoDictionaries = [NSMutableArray array];
	if ([[NSBundle mainBundle] localizedInfoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] localizedInfoDictionary]];
	}
	if ([[NSBundle mainBundle] infoDictionary]) {
		[infoDictionaries addObject:[[NSBundle mainBundle] infoDictionary]];
	}
	for (NSDictionary *infoDictionary in infoDictionaries) {
		if (displayName != nil) {
			break;
		}
		for (NSString *appNameKey in appNameKeys) {
			displayName = [infoDictionary objectForKey:appNameKey];
			if (displayName != nil) {
				break;
			}
		}
	}
	return displayName;
}

- (BOOL)isReady {
	return (self.state == ATBackendStateReady);
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	return [self.dataManager managedObjectContext];
}

- (NSManagedObjectModel *)managedObjectModel {
	return [self.dataManager managedObjectModel];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	return [self.dataManager persistentStoreCoordinator];
}

#pragma mark -

- (void)createConversation {
	if (self.conversationOperation != nil || self.session.token != nil) {
		return;
	}

	self.conversationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"POST" payload:self.session.conversationCreationJSON delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.conversationOperation];
}

- (void)updateConfigurationIfNeeded {
	if (self.configurationOperation != nil) {
		return;
	}

	self.configurationOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation/configuration" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	if (!self.session.token && self.conversationOperation) {
		[self.configurationOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.configurationOperation];
}

- (void)updateEngagementManifestIfNeeded {
	if (self.manifestOperation != nil || self.localEngagementManifestURL != nil) {
		return;
	}

	self.manifestOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"interactions" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	if (!self.session.token && self.conversationOperation) {
		[self.manifestOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.manifestOperation];
}

#pragma mark -

- (void)processQueuedRecords {
	if (self.isReady) {
		[self.serialQueue resumeWithDependency:self.conversationOperation];
	}
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
		ApptentiveLogError(@"@% %@ failed with error: %@", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);
	}

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.",  operation.request.HTTPMethod, operation.request.URL.absoluteString, self.networkQueue.backoffDelay);
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
	NSString *personID = conversationResponse[@"person_id"];
	NSString *deviceID = conversationResponse[@"device_id"];

	if (token != nil) {
		[self.session setToken:token personID:personID deviceID:deviceID];

		[self saveSession];

		self.networkQueue.token = token;
		self.serialQueue.token = token;

		[self processQueuedRecords];
	}
}

- (void)processConfigurationResponse:(NSDictionary *)configurationResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_configuration = [[ApptentiveAppConfiguration alloc] initWithJSONDictionary:configurationResponse cacheLifetime:cacheLifetime];

	[self saveConfiguration];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ATConfigurationPreferencesChangedNotification object:self.configuration];
	});
}

- (void)processManifestResponse:(NSDictionary *)manifestResponse cacheLifetime:(NSTimeInterval)cacheLifetime {
	_manifest = [[ApptentiveEngagementManifest alloc] initWithJSONDictionary:manifestResponse cacheLifetime:cacheLifetime];

	[self saveManifest];

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveInteractionsDidUpdateNotification object:self.manifest];
		[self updateMessageCheckingTimer];
	});
}

- (BOOL)saveSession {
	return [NSKeyedArchiver archiveRootObject:self.session toFile:[self sessionPath]];
}

- (BOOL)saveConfiguration {
	return [NSKeyedArchiver archiveRootObject:self.configuration toFile:[self configurationPath]];
}

- (BOOL)saveManifest {
	return [NSKeyedArchiver archiveRootObject:_manifest toFile:[self manifestPath]];
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
	if (self.presentedMessageCenterViewController) {
		self.presentedMessageCenterViewController = nil;
	}
}

#pragma mark - Session delegate

- (void)session:(ApptentiveSession *)session conversationDidChange:(NSDictionary *)payload {
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.parentContext = self.managedObjectContext;

	[context performBlock:^{
		[ApptentiveSerialRequest enqueueRequestWithPath:@"conversation" method:@"PUT" payload:payload attachments:nil identifier:nil inContext:context];
	}];

	[self saveSession];
}

- (void)session:(ApptentiveSession *)session personDidChange:(NSDictionary *)diffs {
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.parentContext = self.managedObjectContext;

	[context performBlock:^{
		[ApptentiveSerialRequest enqueueRequestWithPath:@"people" method:@"PUT" payload:diffs attachments:nil identifier:nil inContext:context];
	}];

	[self saveSession];
}

- (void)session:(ApptentiveSession *)session deviceDidChange:(NSDictionary *)diffs {
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	context.parentContext = self.managedObjectContext;

	[context performBlock:^{
		[ApptentiveSerialRequest enqueueRequestWithPath:@"devices" method:@"PUT" payload:diffs attachments:nil identifier:nil inContext:context];
	}];

	[self saveSession];
}

#pragma mark -

- (NSURL *)apptentivePrivacyPolicyURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/privacy"];
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
	ApptentiveMessageSender *sender = [ApptentiveMessageSender findSenderWithID:self.session.person.identifier inContext:self.managedObjectContext];
	if (sender) {
		message.sender = sender;
	}

	NSError *error;
	if (![[self managedObjectContext] save:&error]) {
		ApptentiveLogError(@"Error (%@) saving message: %@", error, message);
		return NO;
	}

	[ApptentiveSerialRequest enqueueRequestWithPath:@"messages" method:@"POST" payload:message.apiJSON attachments:message.attachments identifier:message.pendingMessageID inContext:[self managedObjectContext]];

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
		UINavigationController *navigationController = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"NoPayloadNavigation"];

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
			[self checkForMessagesAtRefreshInterval:self.configuration.messageCenter.backgroundPollingInterval];
		} else {
			[self checkForMessagesAtRefreshInterval:self.configuration.messageCenter.foregroundPollingInterval];
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

		self.messageRetrievalTimer = [NSTimer timerWithTimeInterval:refreshInterval target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES];
		NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
		[mainRunLoop addTimer:self.messageRetrievalTimer forMode:NSDefaultRunLoopMode];
	}
}

- (void)messageCenterEnteredForeground {
	@synchronized(self) {
		_messageCenterInForeground = YES;

		[self checkForMessages];

		[self updateMessageCheckingTimer];
	}
}

- (void)messageCenterLeftForeground {
	@synchronized(self) {
		_messageCenterInForeground = NO;

		[self updateMessageCheckingTimer];
	}
}

- (void)checkForMessages {
	if (!self.isReady || self.messageOperation != nil) {
		return;
	}

	self.messageOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	if (!self.session.token && self.conversationOperation) {
		[self.messageOperation addDependency:self.conversationOperation];
	}

	[self.networkQueue addOperation:self.messageOperation];
}

- (void)processMessagesResponse:(NSDictionary *)response {
	NSArray *messages = response[@"items"];

	if ([messages isKindOfClass:[NSArray class]]) {
		NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		context.parentContext = self.managedObjectContext;

		[context performBlock:^{
			NSString *lastMessageID = nil;

			for (NSDictionary *messageJSON in messages) {
				ApptentiveMessage *message = [ApptentiveMessage messageWithJSON:messageJSON inContext:context];

				if (message) {
					if ([self.session.person.identifier isEqualToString:message.sender.apptentiveID]) {
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
				if (![self.managedObjectContext save:&mainContextSaveError]) {
					ApptentiveLogError(@"Failed to save received messages in main context: %@", error);
				}

				[self completeMessageFetchWithResult:lastMessageID != nil ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData];

				[self.session didDownloadMessagesUpTo:lastMessageID];
			});
		}];
	} else {
		ApptentiveLogError(@"Expected array of dictionaries for message response");
		[self completeMessageFetchWithResult:UIBackgroundFetchResultFailed];
	}
}

- (void)fetchMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler {
	self.backgroundFetchBlock = completionHandler;

	[self checkForMessages];
}

- (void)completeMessageFetchWithResult:(UIBackgroundFetchResult)fetchResult {
	if (self.backgroundFetchBlock) {
		self.backgroundFetchBlock(fetchResult);

		self.backgroundFetchBlock = nil;
	}
}

#pragma mark Message send progress

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if (object == self.serialQueue && ([keyPath isEqualToString:@"messageSendProgress"] || [keyPath isEqualToString:@"messageTaskCount"])) {
		NSNumber *numberProgress = change[NSKeyValueChangeNewKey];
		float progress = [numberProgress isKindOfClass:[NSNumber class]] ? numberProgress.floatValue : 0.0;

		if (self.serialQueue.messageTaskCount > 0 && numberProgress.floatValue < 0.05) {
			progress = 0.05;
		} else if (self.serialQueue.messageTaskCount == 0) {
			progress = 0;
		}

		[self.messageDelegate backend:self messageProgressDidChange:progress];
	}
}

#pragma mark - Paths

- (NSString *)supportDirectoryPath {
	if (!_supportDirectoryPath) {
		NSString *appSupportDirectoryPath = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
		NSString *apptentiveDirectoryPath = [appSupportDirectoryPath stringByAppendingPathComponent:@"com.apptentive.feedback"];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSError *error = nil;

		if (![fm createDirectoryAtPath:apptentiveDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(@"Failed to create support directory: %@", apptentiveDirectoryPath);
			ApptentiveLogError(@"Error was: %@", error);
			return nil;
		}

		if (![fm setAttributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication } ofItemAtPath:apptentiveDirectoryPath error:&error]) {
			ApptentiveLogError(@"Failed to set file protection level: %@", apptentiveDirectoryPath);
			ApptentiveLogError(@"Error was: %@", error);
		}

		_supportDirectoryPath = apptentiveDirectoryPath;
	}

	return _supportDirectoryPath;
}

- (NSString *)attachmentDirectoryPath {
	NSString *supportPath = [self supportDirectoryPath];
	if (!supportPath) {
		return nil;
	}
	NSString *newPath = [supportPath stringByAppendingPathComponent:@"attachments"];
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

- (NSString *)sessionPath {
	return [[self supportDirectoryPath] stringByAppendingPathComponent:@"session"];
}

- (NSString *)conversationPath {
	return [[self supportDirectoryPath] stringByAppendingPathComponent:@"conversation"];
}

- (NSString *)configurationPath {
	return [[self supportDirectoryPath] stringByAppendingPathComponent:@"configuration"];
}

- (NSString *)manifestPath {
	return [[self supportDirectoryPath] stringByAppendingPathComponent:@"interactions"];
}

#pragma mark - Debugging

- (void)setLocalEngagementManifestURL:(NSURL *)localEngagementManifestURL {
	if (_localEngagementManifestURL != localEngagementManifestURL) {
		_localEngagementManifestURL = localEngagementManifestURL;

		if (localEngagementManifestURL == nil) {
			_manifest = [NSKeyedUnarchiver unarchiveObjectWithFile:[self manifestPath]];
			[self updateEngagementManifestIfNeeded];
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
