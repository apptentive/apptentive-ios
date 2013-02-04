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
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ApptentiveMetrics.h"
#import "ATReachability.h"
#import "ATTaskQueue.h"
#import "ATUtilities.h"
#import "ATWebClient.h"
#import "ATPersonUpdater.h"
#import "ATDeviceUpdater.h"
#import "ATMessageDisplayType.h"
#import "ATGetMessagesTask.h"

NSString *const ATBackendNewAPIKeyNotification = @"ATBackendNewAPIKeyNotification";
NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";
NSString *const ATInfoDistributionKey = @"ATInfoDistributionKey";

static ATBackend *sharedBackend = nil;

@interface ATBackend ()
- (void)updateRatingConfigurationIfNeeded;
@end

@interface ATBackend (Private)
- (void)setup;
- (void)updateWorking;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)checkForMessages;
@end

@interface ATBackend ()
@property (nonatomic, assign) BOOL working;
- (void)updatePersonIfNeeded;
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
		NSLog(@"Unable to find image named: %@", name);
		NSLog(@"sought at: %@", imagePath);
		NSLog(@"bundle is: %@", [ATConnect resourceBundle]);
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
		NSLog(@"Unable to find image named: %@", name);
		NSLog(@"sought at: %@", imagePath);
		NSLog(@"bundle is: %@", [ATConnect resourceBundle]);
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
		NSLog(@"Failed to create support directory: %@", newPath);
		NSLog(@"Error was: %@", error);
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
		NSLog(@"Failed to create attachments directory: %@", newPath);
		NSLog(@"Error was: %@", error);
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
			[self updatePersonIfNeeded];
			if (!deviceUpdater) {
				if ([ATDeviceUpdater shouldUpdate]) {
					deviceUpdater = [[ATDeviceUpdater alloc] initWithDelegate:self];
					[deviceUpdater update];
				}
			}
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
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
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
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			NSLog(@"Unresolved error2 %@, %@", error2, [error2 userInfo]);
			//        abort();
		}
    }
    return persistentStoreCoordinator;
}

- (void)updatePersonIfNeeded {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(updatePersonIfNeeded) withObject:nil waitUntilDone:NO];
		return;
	}
	if (!personUpdater) {
		if (![ATPersonUpdater personExists]) {
			personUpdater = [[ATPersonUpdater alloc] initWithDelegate:self];
			[personUpdater createPerson];
		}
	}
}

#pragma mark ATPersonUpdaterDelegate
- (void)personUpdater:(ATPersonUpdater *)aPersonUpdater didFinish:(BOOL)success {
	if (aPersonUpdater == personUpdater) {
		[personUpdater release], personUpdater = nil;
		if (!success) {
			// Retry in 20 seconds.
			[self performSelector:@selector(updatePersonIfNeeded) withObject:nil afterDelay:20];
		}
	}
}

#pragma mark ATDeviceUpdaterDelegate
- (void)deviceUpdater:(ATDeviceUpdater *)aDeviceUpdater didFinish:(BOOL)success {
	if (deviceUpdater == aDeviceUpdater) {
		[deviceUpdater release], deviceUpdater = nil;
	}
}

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
			messageRetrievalTimer = [[NSTimer timerWithTimeInterval:60*5. target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES] retain];
			NSRunLoop *mainRunLoop = [NSRunLoop mainRunLoop];
			[mainRunLoop addTimer:messageRetrievalTimer forMode:NSDefaultRunLoopMode];
		}
	}
	[pool release], pool = nil;
}
@end
