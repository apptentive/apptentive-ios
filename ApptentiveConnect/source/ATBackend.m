//
//  ATBackend.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/19/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATTaskQueue.h"

static ATBackend *sharedBackend = nil;

@interface ATBackend (Private)
- (void)setup;
- (void)teardown;
- (void)stopWorking:(NSNotification *)notification;
- (void)startWorking:(NSNotification *)notification;
@end

@interface ATBackend ()
@property (nonatomic, assign) BOOL working;
@end

@implementation ATBackend
@synthesize working;

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

- (void)updateAPIKey:(NSString *)newAPIKey {
    //TODO
}

- (void)sendFeedback:(ATFeedback *)feedback {
    //TODO
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

#pragma mark Accessors
- (void)setWorking:(BOOL)newWorking {
    if (working != newWorking) {
        working = newWorking;
        if (working) {
            [[ATTaskQueue sharedTaskQueue] start];
        } else {
            [[ATTaskQueue sharedTaskQueue] stop];
            [ATTaskQueue destroySharedTaskQueue];
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
}

- (void)teardown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Notification Handling
- (void)stopWorking:(NSNotification *)notification {
    self.working = NO;
}

- (void)startWorking:(NSNotification *)notification {
    self.working = YES;
}
@end
