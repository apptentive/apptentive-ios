//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATContactStorage.h"
#import "ATContactUpdater.h"
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ATReachability.h"
#import "ATTaskQueue.h"

static ATBackend *sharedBackend = nil;

@interface ATBackend (Private)
- (void)setup;
- (void)teardown;
- (void)networkStatusChanged:(NSNotification *)notification;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
- (void)contactUpdaterFinished:(NSNotification *)notification;
@end

@interface ATBackend ()
@property (nonatomic, assign) BOOL working;
@end

@implementation ATBackend
@synthesize apiKey, working;

+ (ATBackend *)sharedBackend {
    @synchronized(self) {
        if (sharedBackend == nil) {
            sharedBackend = [[self alloc] init];
        }
    }
    return sharedBackend;
}

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

- (id)init {
    if ((self = [super init])) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)setApiKey:(NSString *)anAPIKey {
    if (apiKey != anAPIKey) {
        [apiKey release];
        apiKey = nil;
        apiKey = [anAPIKey retain];
        if (apiKey == nil) {
            self.working = NO;
        } else {
            self.working = NO;
            self.working = YES;
        }
    }
}

- (void)sendFeedback:(ATFeedback *)feedback {
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
}

- (void)updateUserData {
    if (contactUpdater) {
        [contactUpdater cancel];
        [contactUpdater release];
        contactUpdater = nil;
    }
    contactUpdater = [[ATContactUpdater alloc] init];
    [contactUpdater update];
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
    return [[UIDevice currentDevice] uniqueIdentifier];
}

#pragma mark Accessors
- (void)setWorking:(BOOL)newWorking {
    if (working != newWorking) {
        working = newWorking;
        if (working) {
            [[ATTaskQueue sharedTaskQueue] start];
			
			if ([[ATContactStorage sharedContactStorage] shouldCheckForUpdate] && !userDataWasUpdated) {
                [self updateUserData];
            }
        } else {
            [[ATTaskQueue sharedTaskQueue] stop];
            [ATTaskQueue releaseSharedTaskQueue];
        }
    }
}
@end

@implementation ATBackend (Private)
- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationWillTerminateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    
    if (&UIApplicationDidEnterBackgroundNotification != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdaterFinished:) name:ATContactUpdaterFinished object:nil];
	
	[ATReachability sharedReachability];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:ATReachabilityStatusChanged object:nil];
}

- (void)teardown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [contactUpdater cancel];
    [contactUpdater release];
    contactUpdater = nil;
    self.apiKey = nil;
}

#pragma mark Notification Handling
- (void)networkStatusChanged:(NSNotification *)notification {
	ATNetworkStatus status = [[ATReachability sharedReachability] currentNetworkStatus];
	if (status == ATNetworkNotReachable) {
		self.working = NO;
	} else if ([[ATTaskQueue sharedTaskQueue] count]) {
		self.working = YES;
	}
}

- (void)stopWorking:(NSNotification *)notification {
    self.working = NO;
}

- (void)startWorking:(NSNotification *)notification {
    self.working = YES;
}

- (void)contactUpdaterFinished:(NSNotification *)notification {
    if (contactUpdater) {
        [contactUpdater release];
        contactUpdater = nil;
    }
    userDataWasUpdated = YES;
}
@end
