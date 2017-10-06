//
//  ApptentiveConversationPayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;


@interface ApptentiveSDKAppReleasePayload : ApptentivePayload

@property (readonly, nonatomic) ApptentiveConversation *conversation;

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
