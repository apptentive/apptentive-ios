//
//  ApptentiveDispatchQueue.m
//  Apptentive
//
//  Created by Alex Lementuev on 12/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDispatchQueue.h"

#import "ApptentiveAssert.h"
#import "ApptentiveDefines.h"
#import "ApptentiveGCDDispatchQueue.h"

static ApptentiveDispatchQueue * _mainQueue;
static ApptentiveDispatchQueue * _backgroundQueue;

@implementation ApptentiveDispatchQueue

+ (void)initialize {
	if ([self class] == [ApptentiveDispatchQueue class]) {
		_mainQueue = [[ApptentiveGCDDispatchQueue alloc] initWithQueue:dispatch_get_main_queue()];
		_backgroundQueue = [[ApptentiveGCDDispatchQueue alloc] initWithQueue:dispatch_queue_create("Apptentive Background Queue", DISPATCH_QUEUE_CONCURRENT)];
	}
}

+ (instancetype)main {
	return _mainQueue;
}

+ (instancetype)background {
	return _backgroundQueue;
}

+ (instancetype)createQueueWithName:(NSString *)name concurrencyType:(ApptentiveDispatchQueueConcurrencyType)type {
	if (type == ApptentiveDispatchQueueConcurrencyTypeSerial) {
		const char *label = name.UTF8String;
		return [[ApptentiveGCDDispatchQueue alloc] initWithQueue:dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL)];
	}
	
	if (type == ApptentiveDispatchQueueConcurrencyTypeConcurrent) {
		const char *label = name.UTF8String;
		return [[ApptentiveGCDDispatchQueue alloc] initWithQueue:dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT)];
	}
	
	ApptentiveAssertFail(@"Unexpected concurrency type for queue '%@': %ld", name, type);
	return nil;
}

- (void)dispatchAsync:(void (^)(void))task {
	[self dispatchAsync:task afterDelay:0.0];
}

- (void)dispatchAsync:(void (^)(void))task afterDelay:(NSTimeInterval)delay {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
}

@end
