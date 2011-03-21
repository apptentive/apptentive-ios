//
//  ATTaskQueue.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/21/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATTaskQueue.h"
#import "ATBackend.h"
#import "ATTask.h"

#define kATTaskQueueCodingVersion 1

static ATTaskQueue *sharedTaskQueue = nil;

@interface ATTaskQueue (Private)
- (void)setup;
- (void)teardown;
@end

@implementation ATTaskQueue
+ (NSString *)taskQueuePath {
    return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"tasks.objects"];
}

+ (BOOL)serializedQueueExists {
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:[ATTaskQueue taskQueuePath]];
}


+ (ATTaskQueue *)sharedTaskQueue {
    @synchronized(self) {
        if (sharedTaskQueue == nil) {
            if ([ATTaskQueue serializedQueueExists]) {
                sharedTaskQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:[ATTaskQueue taskQueuePath]];
                if (!sharedTaskQueue) {
                    sharedTaskQueue = [[ATTaskQueue alloc] init];
                }
            }
        }
    }
    return sharedTaskQueue;
}

+ (void)destroySharedTaskQueue {
    @synchronized(self) {
        if (sharedTaskQueue != nil) {
            [sharedTaskQueue release];
            sharedTaskQueue = nil;
        }
    }
}

- (id)init {
    if ((self = [super init])) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super init])) {
        int version = [coder decodeIntForKey:@"version"];
        if (version == kATTaskQueueCodingVersion) {
            tasks = [coder decodeObjectForKey:@"tasks"];
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:kATTaskQueueCodingVersion forKey:@"version"];
    [coder encodeObject:tasks forKey:@"tasks"];
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}


- (void)start {
    if (activeTask) return;
    
    if ([tasks count]) {
        activeTask = [tasks objectAtIndex:0];
        [self observeValueForKeyPath:@"finished" ofObject:activeTask change:NSKeyValueObservingOptionNew context:NULL];
        [activeTask start];
    }
}

- (void)stop {
    if (activeTask) {
        [activeTask stop];
        [activeTask removeObserver:self forKeyPath:@"finished"];
        activeTask = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"finished"] && [(ATTask *)object finished]) {
		[object removeObserver:self forKeyPath:@"finished"];
        activeTask = nil;
        [tasks removeObject:object];
        [self start];
	}
}
@end

@implementation ATTaskQueue (Private)
- (void)setup {
    tasks = [[NSMutableArray alloc] init];
}

- (void)teardown {
    [self stop];
    [tasks release];
    tasks = nil;
}
@end

