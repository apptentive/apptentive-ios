//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATBackend.h"
#import "ATContactStorage.h"
#import "ATContactUpdater.h"
#import "ATFeedback.h"
#import "ATFeedbackTask.h"
#import "ATTaskQueue.h"

static ATBackend *sharedBackend = nil;

@interface ATBackend (Private)
- (void)setup;
- (void)teardown;
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
            if (!userDataWasUpdated) {
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopWorking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startWorking:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdaterFinished:) name:ATContactUpdaterFinished object:nil];
}

- (void)teardown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [contactUpdater cancel];
    [contactUpdater release];
    contactUpdater = nil;
    self.apiKey = nil;
}

#pragma mark Notification Handling
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
