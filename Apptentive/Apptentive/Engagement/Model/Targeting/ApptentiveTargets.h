//
//  ApptentiveTargets.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;

@interface ApptentiveTargets : NSObject <NSSecureCoding>

@property (readonly, nonatomic, strong) NSDictionary *invocations;

- (nullable instancetype)initWithTargetsDictionary:(NSDictionary <NSString *, NSArray *>*)targetsDictionary;

- (nullable NSString *)interactionIdentifierForEvent:(NSString *)event conversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END

