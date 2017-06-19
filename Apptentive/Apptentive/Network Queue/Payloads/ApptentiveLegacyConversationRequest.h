//
//  ApptentiveLegacyConversationRequest.h
//  Apptentive
//
//  Created by Alex Lementuev on 5/15/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

@class ApptentiveConversation;

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveLegacyConversationRequest : ApptentiveRequest

@property (readonly, nonatomic) ApptentiveConversation *conversation;

- (nullable instancetype)initWithConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
