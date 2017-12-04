//
//  ApptentiveGCDDispatchQueue.m
//  Apptentive
//
//  Created by Alex Lementuev on 12/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveGCDDispatchQueue.h"

#import "ApptentiveDefines.h"

@interface ApptentiveGCDDispatchQueue ()

@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly, nullable) NSString *name;

@end

@implementation ApptentiveGCDDispatchQueue

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(queue);
	self = [super init];
	if (self) {
		_queue = queue;
	}
	return self;
}

- (void)dispatchAsync:(void (^)(void))task afterDelay:(NSTimeInterval)delay {
	ApptentiveAssertNotNil(task, @"Attemped to dispatch nil task on '%@' queue", self.name);
	if (task != nil) {
		if (delay > 0.0) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), _queue, ^{
				[self dispatchTaskGuarded:task];
			});
		} else {
			dispatch_async(_queue, ^{
				[self dispatchTaskGuarded:task];
			});
		}
	}
}

- (void)dispatchTaskGuarded:(void (^)(void))task {
	@try {
		task();
	} @catch (NSException *exception) {
		ApptentiveLogCrit(@"Exception while dispatching task: %@", exception);
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)name {
	const char *label = dispatch_queue_get_label(_queue);
	return label != NULL ? [[NSString alloc] initWithUTF8String:label] : nil;
}

@end
