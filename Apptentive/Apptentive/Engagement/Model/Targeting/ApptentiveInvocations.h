//
//  ApptentiveInvocations.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;


@interface ApptentiveInvocations : NSObject <NSSecureCoding>

@property (readonly, nonatomic) NSArray *targets;

- (instancetype)initWithArray:(NSArray *)targetsArray;

- (nullable NSString *)interactionIdentifierForConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
