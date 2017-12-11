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

NSString * _Nullable ApptentiveGetCurrentThreadName() {
	if ([NSThread currentThread].isMainThread) {
		return nil;
	}
	
	NSString *threadName = [NSThread currentThread].name;
	if (threadName.length > 0) {
		return threadName;
	}
	
	NSOperationQueue *currentOperationQueue = [NSOperationQueue currentQueue];
	if (currentOperationQueue != nil) {
		return currentOperationQueue.name;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	
	dispatch_queue_t currentDispatchQueue = dispatch_get_current_queue();
	if (currentDispatchQueue != NULL) {
		if (currentDispatchQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			return @"QUEUE_DEFAULT";
		}
		if (currentDispatchQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			return @"QUEUE_HIGH";
		}
		if (currentDispatchQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
			return @"QUEUE_LOW";
		}
		if (currentDispatchQueue == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
			return @"QUEUE_BACKGROUND";
		}
		
		const char *label = dispatch_queue_get_label(currentDispatchQueue);
		return label != NULL ? [NSString stringWithFormat:@"%s", label] : @"Serial queue";
	}
	
#pragma clang diagnostic pop
	
	return @"Background Thread";
}

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

+ (nullable instancetype)createQueueWithName:(NSString *)name concurrencyType:(ApptentiveDispatchQueueConcurrencyType)type {
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

- (void)dispatchAsync:(void (^)(void))task withDependency:(nonnull NSOperation *)dependency {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
}

#pragma mark -
#pragma mark Properties

- (BOOL)isSuspended {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
	return NO;
}

- (void)setSuspended:(BOOL)suspended {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
}

- (BOOL)isCurrent {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
	return NO;
}

@end
