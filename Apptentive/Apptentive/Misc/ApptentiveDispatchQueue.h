//
//  ApptentiveDispatchQueue.h
//  Apptentive
//
//  Created by Alex Lementuev on 12/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
	ApptentiveDispatchQueueConcurrencyTypeSerial,
	ApptentiveDispatchQueueConcurrencyTypeConcurrent
} ApptentiveDispatchQueueConcurrencyType;

extern NSString * _Nullable ApptentiveGetCurrentThreadName(void);

@class ApptentiveDispatchTask;

@interface ApptentiveDispatchQueue : NSObject

@property (nonatomic, assign, getter=isSuspended) BOOL suspended;
@property (nonatomic, readonly, getter=isCurrent) BOOL current;

/**
 @return a global serial dispatch queue associated with app's UI-thread.
 */
+ (instancetype)main;

/**
 Creates a background queue with a specified name and concurrency type
 */
+ (nullable instancetype)createQueueWithName:(NSString *)name concurrencyType:(ApptentiveDispatchQueueConcurrencyType)type qualityOfService:(NSQualityOfService)qualityOfService;

- (void)dispatchAsync:(void (^)(void))task;

- (void)dispatchAsync:(void (^)(void))task withDependency:(NSOperation *)dependency;

- (void)dispatchTask:(ApptentiveDispatchTask *)task;

- (void)dispatchTaskOnce:(ApptentiveDispatchTask *)task;

@end

NS_ASSUME_NONNULL_END
