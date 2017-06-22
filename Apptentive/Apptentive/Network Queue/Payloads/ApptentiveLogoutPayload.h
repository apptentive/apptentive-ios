//
//  ApptentiveLogoutPayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveLogoutPayload : ApptentivePayload

@property (readonly, nonatomic) NSString *conversationToken;

- (nullable instancetype)initWithConversationToken:(NSString *)token;

@end

NS_ASSUME_NONNULL_END
