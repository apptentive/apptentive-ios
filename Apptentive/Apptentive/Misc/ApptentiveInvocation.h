//
//  ApptentiveClass.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/8/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveInvocation : NSObject

@property (nonatomic, strong, readonly) id target;

+ (BOOL)classAvailable:(NSString *)className;

+ (nullable instancetype)fromClassName:(NSString *)className;
+ (nullable instancetype)fromObject:(id)object;

- (nullable id)invokeSelector:(NSString *)selectorName;
- (nullable NSNumber *)invokeBoolSelector:(NSString *)selectorName;

@end

NS_ASSUME_NONNULL_END
