//
//  ApptentiveConversationBaseRequest.h
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"

@interface ApptentiveConversationBaseRequest : ApptentiveRequest

@property (nonnull, readonly, copy) NSString *conversationId;

- (nullable instancetype)initWithConversationId:( NSString * _Nonnull )conversationId;

@end
