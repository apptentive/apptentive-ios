//
//  ApptentiveConversationRequest.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

@class ApptentiveConversation;

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveConversationRequest : ApptentiveRequest

@property (readonly, nonatomic) ApptentiveConversation *conversation;

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
