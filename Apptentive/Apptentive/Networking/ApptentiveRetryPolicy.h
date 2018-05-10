//
//  ApptentiveRetryPolicy.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/2/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveRetryPolicy : NSObject

@property (readonly, nonatomic) NSTimeInterval initialBackoff;
@property (readonly, nonatomic) float base;

- (instancetype)initWithInitialBackoff:(NSTimeInterval)initialBackoff base:(float)base;

@property (assign, nonatomic) BOOL shouldAddJitter;
@property (assign, nonatomic) NSTimeInterval cap;

@property (strong, nonatomic) NSIndexSet *retryStatusCodes;
@property (strong, nonatomic) NSIndexSet *failStatusCodes;

@property (readonly, nonatomic) NSTimeInterval retryDelay;

- (BOOL)shouldRetryRequestWithStatusCode:(NSInteger)statusCode;
- (void)increaseRetryDelay;
- (void)resetRetryDelay;

@end

NS_ASSUME_NONNULL_END
