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
		_mainQueue = [[ApptentiveGCDDispatchQueue alloc] initWithQueue:NSOperationQueue.mainQueue];
		
		_backgroundQueue = [self createQueueWithName:@"Apptentive Background Queue" concurrencyType:ApptentiveDispatchQueueConcurrencyTypeConcurrent];
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
		NSOperationQueue *queue = [NSOperationQueue new];
		queue.name = name;
		queue.maxConcurrentOperationCount = 1;
		return [[ApptentiveGCDDispatchQueue alloc] initWithQueue:queue];
	}
	
	if (type == ApptentiveDispatchQueueConcurrencyTypeConcurrent) {
		NSOperationQueue *queue = [NSOperationQueue new];
		queue.name = name;
		return [[ApptentiveGCDDispatchQueue alloc] initWithQueue:queue];
	}
	
	ApptentiveAssertFail(@"Unexpected concurrency type for queue '%@': %ld", name, type);
	return nil;
}

- (void)dispatchAsync:(void (^)(void))task {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
}

@end
