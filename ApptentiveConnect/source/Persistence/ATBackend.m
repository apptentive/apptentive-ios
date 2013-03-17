//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATBackend.h"
#import "ATAppConfigurationUpdateTask.h"
#import "ATConnect.h"
#import "ATContactStorage.h"
#import "ATDeviceUpdater.h"
#import "ATFakeMessage.h"
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ApptentiveMetrics.h"
#import "ATReachability.h"
#import "ATTaskQueue.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATMessageDisplayType.h"
#import "ATGetMessagesTask.h"
#import "ATTextMessage.h"
#import "ATLog.h"

NSString *const ATBackendNewAPIKeyNotification = @"ATBackendNewAPIKeyNotification";
NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";
NSString *const ATInfoDistributionKey = @"ATInfoDistributionKey";

static ATBackend *sharedBackend = nil;

@interface ATBackend ()
- (void)updateRatingConfigurationIfNeeded;
@end

@interface ATBackend (Private)
- (void)clearTemporaryData;
- (void)setup;
- (void)updateWorking;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)checkForMessages;
- (void)startMonitoringUnreadMessages;
@end

@interface ATBackend ()
@property (nonatomic, assign) BOOL working;
- (void)updateActivityFeedIfNeeded;
- (void)updateDeviceIfNeeded;
@end

@implementation ATBackend
@synthesize apiKey, working, currentFeedback, persistentStoreCoordinator;

+ (ATBackend *)sharedBackend {
	@synchronized(self) {
		if (sharedBackend == nil) {
			sharedBackend = [[self alloc] init];
			[ApptentiveMetrics sharedMetrics];
			
			[ATMessageDisplayType setupSingletons];
			
			[sharedBackend performSelector:@selector(checkForMessages) withObject:nil afterDelay:8];
			[sharedBackend performSelector:@selector(clearTemporaryData) withObject:nil afterDelay:0.1];
		}
	}
	return sharedBackend;
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	UIImage *result = nil;
	CGFloat scale = [[UIScreen mainScreen] scale];
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [UIImage imageWithContentsOfFile:imagePath];
	} else {
		result = [UIImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#elif TARGET_OS_MAC
+ (NSImage *)imageNamed:(NSString *)name {
	NSString *imagePath = nil;
	NSImage *result = nil;
	CGFloat scale = 1.0;
	
	if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
		scale = (CGFloat)[[NSScreen mainScreen] backingScaleFactor];
	}
	if (scale > 1.0) {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png"];
	} else {
		imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png"];
	}
	
	if (!imagePath) {
		if (scale > 1.0) {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@@2x", name] ofType:@"png" inDirectory:@"generated"];
		} else {
			imagePath = [[ATConnect resourceBundle] pathForResource:[NSString stringWithFormat:@"%@", name] ofType:@"png" inDirectory:@"generated"];
		}
	}
	
	if (imagePath) {
		result = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	} else {
		result = [NSImage imageNamed:name];
	}
	if (!result) {
		ATLogError(@"Unable to find image named: %@", name);
		ATLogError(@"sought at: %@", imagePath);
		ATLogError(@"bundle is: %@", [ATConnect resourceBundle]);
	}
	return result;
}
#endif

- (id)init {
	if ((self = [super init])) {
		[self setup];
	}
	return self;
}

- (void)dealloc {
	[messageRetrievalTimer invalidate];
	[messageRetrievalTimer release], messageRetrievalTimer = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[apiKey release], apiKey = nil;
	[currentFeedback release], currentFeedback = nil;
	[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
	[managedObjectContext release], managedObjectContext = nil;
	[managedObjectModel release], managedObjectModel = nil;
	[super dealloc];
}

- (void)setApiKey:(NSString *)anAPIKey {
	if (apiKey != anAPIKey) {
		[apiKey release];
		apiKey = nil;
		apiKey = [anAPIKey retain];
		if (apiKey == nil) {
			apiKeySet = NO;
		} else {
			apiKeySet = YES;
		}
		[self updateWorking];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATBackendNewAPIKeyNotification object:nil];
	}
}

- (void)sendFeedback:(ATFeedback *)feedback {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if ([[NSThread currentThread] isMainThread]) {
		[feedback retain];
		[self performSelectorInBackground:@selector(sendFeedback:) withObject:feedback];
		[pool release], pool = nil;
		return;
	}
	if (feedback == self.currentFeedback) {
		self.currentFeedback = nil;
	}
	ATContactStorage *contact = [ATContactStorage sharedContactStorage];
	contact.name = feedback.name;
	contact.email = feedback.email;
	contact.phone = feedback.phone;
	[ATContactStorage releaseSharedContactStorage];
	contact = nil;
	
	ATFeedbackTask *task = [[ATFeedbackTask alloc] init];
	task.feedback = feedback;
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[task release];
	task = nil;
	
	[feedback release];
	[pool release];
}

- (void)updateRatingConfigurationIfNeeded {
	ATAppConfigurationUpdateTask *task = [[ATAppConfigurationUpdateTask alloc] init];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[task release], task = nil;
}

- (NSString *)supportDirectoryPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	NSString *newPath = [path stringByAppendingPathComponent:@"com.apptentive.feedback"];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	BOOL result = [fm createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
	if (!result) {
		ATLogError(@"Failed to create support directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
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
		ATLogError(@"Failed to create attachments directory: %@", newPath);
		ATLogError(@"Error was: %@", error);
		return nil;
	}
	return newPath;
}

- (NSString *)deviceUUID {
#if TARGET_OS_IPHONE
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *uuid = [defaults objectForKey:ATUUIDPreferenceKey];
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [NSString stringWithFormat:@"ios:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
		
		[defaults setObject:uuid forKey:ATUUIDPreferenceKey];
		[defaults synchronize];
	}
	return uuid;
#elif TARGET_OS_MAC
	static CFStringRef keyRef = CFSTR("apptentiveUUID");
	static CFStringRef appIDRef = CFSTR("com.apptentive.feedback");
	NSString *uuid = nil;
	uuid = (NSString *)CFPreferencesCopyAppValue(keyRef, appIDRef);
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		uuid = [[NSString alloc] initWithFormat:@"osx:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
		
		CFPreferencesSetValue(keyRef, (CFStringRef)uuid, appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		CFPreferencesSynchronize(appIDRef, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	}
	return [uuid autorelease];
#endif
}

#pragma mark Accessors

- (void)setWorking:(BOOL)newWorking {
	if (working != newWorking) {
		working = newWorking;
		if (working) {
			[[ATTaskQueue sharedTaskQueue] start];
			
			[self updateRatingConfigurationIfNeeded];
			[self updateActivityFeedIfNeeded];
			[self updateDeviceIfNeeded];
		} else {
			[[ATTaskQueue sharedTaskQueue] stop];
			[ATTaskQueue releaseSharedTaskQueue];
		}
	}
}


- (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext {
	@synchronized(self) {
		if (managedObjectContext != nil) {
			return managedObjectContext;
		}
		
		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			managedObjectContext = [[NSManagedObjectContext alloc] init];
			[managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    NSURL *modelURL = [[ATConnect resourceBundle] URLForResource:@"ATDataModel" withExtension:@"momd"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel;
}

#warning Fix before shipping this code.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[NSURL fileURLWithPath:[self supportDirectoryPath]] URLByAppendingPathComponent:@"ATDataModel.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
		
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
		NSError *error2 = nil;
		if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error2]) {
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
			ATLogError(@"Unresolved error %@, %@", error, [error userInfo]);
			ATLogError(@"Unresolved error2 %@, %@", error2, [error2 userInfo]);
			[persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
			//        abort();
		}
    }
    return persistentStoreCoordinator;
}

- (void)updateActivityFeedIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updateActivityFeedIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (!activityFeedUpdater) {
		if (![ATActivityFeedUpdater activityFeedExists]) {
			activityFeedUpdater = [[ATActivityFeedUpdater alloc] initWithDelegate:self];
			[activityFeedUpdater createActivityFeed];
		}
	}
}

- (void)updateDeviceIfNeeded {
	if (![ATActivityFeedUpdater activityFeedExists]) {
		return;
	}
	if (!deviceUpdater) {
		if ([ATDeviceUpdater shouldUpdate]) {
			deviceUpdater = [[ATDeviceUpdater alloc] initWithDelegate:self];
			[deviceUpdater update];
		}
	}
}

#pragma mark NSFetchedResultsControllerDelegate
#if TARGET_OS_IPHONE
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if (controller == unreadCountController) {
		id<NSFetchedResultsSectionInfo> sectionInfo = [[unreadCountController sections] objectAtIndex:0];
		NSUInteger unreadCount = [sectionInfo numberOfObjects];
		if (unreadCount != previousUnreadCount) {
			previousUnreadCount = unreadCount;
			[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterUnreadCountChangedNotification object:nil userInfo:@{@"count":@(previousUnreadCount)}];
		}
	}
}
#endif

#pragma mark ATActivityFeedUpdaterDelegate
- (void)activityFeed:(ATActivityFeedUpdater *)aFeedUpdater createdFeed:(BOOL)success {
	if (activityFeedUpdater == aFeedUpdater) {
		[activityFeedUpdater release], activityFeedUpdater = nil;
		if (!success) {
			// Retry after delay.
			[self performSelector:@selector(updateActivityFeedIfNeeded) withObject:nil afterDelay:20];
		} else {
			// Queued tasks can probably start now.
			ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
			[queue start];
			[self updateDeviceIfNeeded];
		}
	}
}

#pragma mark ATDeviceUpdaterDelegate
- (void)deviceUpdater:(ATDeviceUpdater *)aDeviceUpdater didFinish:(BOOL)success {
	if (deviceUpdater == aDeviceUpdater) {
		[deviceUpdater release], deviceUpdater = nil;
	}
}

#pragma mark -

- (NSURL *)apptentivePrivacyPolicyURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/privacy"];
}

- (NSString *)distributionName {
	static NSString *cachedDistributionName = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
		cachedDistributionName = [(NSString *)[[ATConnect resourceBundle] objectForInfoDictionaryKey:ATInfoDistributionKey] retain];
    });
    return cachedDistributionName;
}

- (NSUInteger)unreadMessageCount {
	return previousUnreadCount;
}
@end

@implementation ATBackend (Private)
- (void)setup {
#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationWillTerminateNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	
	if (&UIApplicationDidEnterBackgroundNotification != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
#elif TARGET_OS_MAC
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:NSApplicationWillTerminateNotification object:nil];
#endif
	
	[ATReachability sharedReachability];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ATReachabilityStatusChanged object:nil];
	[self performSelector:@selector(startMonitoringUnreadMessages) withObject:nil afterDelay:0.2];
}

- (void)updateWorking {
	if (shouldStopWorking) {
		// Probably going into the background or being terminated.
		self.working = NO;
	} else if (apiKeySet && networkAvailable) {
		// API Key is set and the network is up. Start working.
		self.working = YES;
	} else {
		// No API Key or not network, or both. Stop working.
		self.working = NO;
	}
}

#pragma mark Notification Handling
- (void)networkStatusChanged:(NSNotification *)notification {
	ATNetworkStatus status = [[ATReachability sharedReachability] currentNetworkStatus];
	if (status == ATNetworkNotReachable) {
		networkAvailable = NO;
	} else {
		networkAvailable = YES;
	}
	[self updateWorking];
}

- (void)stopWorking:(NSNotification *)notification {
	shouldStopWorking = YES;
	[self updateWorking];
}

- (void)startWorking:(NSNotification *)notification {
	shouldStopWorking = NO;
	[self updateWorking];
}

- (void)checkForMessages {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	@synchronized(self) {
		ATGetMessagesTask *task = [[ATGetMessagesTask alloc] init];
		ATTaskQueue *queue = [ATTaskQueue sharedTaskQueue];
		[queue addTask:task];
		[task release], task = nil;
		if (!messageRetrievalTimer) {
			messageRetrievalTimer = [[NSTimer timerWithTimeInterval:60. target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES] retain];
			NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
			[mainRunLoop addTimer:messageRetrievalTimer forMode:NSDefaultRunLoopMode];
		}
	}
	[pool release], pool = nil;
}

- (void)clearDemoData {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	
	@synchronized(self) {
		NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:@"ATMessage"];
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(sender.apptentiveID == 'demouserid' || sender.apptentiveID = 'demodevid')"];
		fetchTypes.predicate = fetchPredicate;
		NSError *fetchError = nil;
		NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];
		
		if (fetchArray) {
			for (NSManagedObject *fetchedObject in fetchArray) {
				[context deleteObject:fetchedObject];
			}
			[context save:nil];
		}
		
		[fetchTypes release], fetchTypes = nil;
	}
}

- (void)clearTemporaryData {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(clearTemporaryData) withObject:nil waitUntilDone:YES];
		return;
	}
	ATLogInfo(@"Removing temporary data");
	[ATFakeMessage removeFakeMessages];
}

- (void)startMonitoringUnreadMessages {
	@autoreleasepool {
#if TARGET_OS_IPHONE
		if (unreadCountController != nil) {
			ATLogError(@"startMonitoringUnreadMessages called more than once!");
			return;
		}
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[self managedObjectContext]]];
		[request setFetchBatchSize:20];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		[sortDescriptor release], sortDescriptor = nil;
		
		NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"seenByUser == %@", @(NO)];
		request.predicate = unreadPredicate;
		
		NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-unread-messages-cache"];
		newController.delegate = self;
		unreadCountController = newController;
		
		NSError *error = nil;
		if (![unreadCountController performFetch:&error]) {
			ATLogError(@"got an error loading unread messages: %@", error);
			//!! handle me
		} else {
			[self controllerDidChangeContent:unreadCountController];
		}
		
		[request release], request = nil;
#endif
	}
}
@end
