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


NSString *const ATBackendNewAPIKeyNotification = @"ATBackendNewAPIKeyNotification";
NSString *const ATUUIDPreferenceKey = @"ATUUIDPreferenceKey";

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
@end

@interface ATBackend ()
@property (nonatomic, assign) BOOL working;
@end

@implementation ATBackend
@synthesize apiKey, working, currentFeedback;

+ (ATBackend *)sharedBackend {
	@synchronized(self) {
		if (sharedBackend == nil) {
			sharedBackend = [[self alloc] init];
			[ApptentiveMetrics sharedMetrics];
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
	CGFloat scale = [[NSScreen mainScreen] userSpaceScaleFactor];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[apiKey release], apiKey = nil;
	[currentFeedback release], currentFeedback = nil;
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
	
	// If we don't need the screenshot, discard it.
	if (feedback.screenshot && !feedback.screenshotSwitchEnabled) {
		feedback.screenshot = nil;
	}
	
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
		} else {
			[[ATTaskQueue sharedTaskQueue] stop];
			[ATTaskQueue releaseSharedTaskQueue];
		}
	}
}


- (NSURL *)apptentiveHomepageURL {
	return [NSURL URLWithString:@"http://www.apptentive.com/"];
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
@end
