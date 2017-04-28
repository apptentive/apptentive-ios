//
//  ApptentiveConversationBaseRequest.m
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationBaseRequest.h"

@implementation ApptentiveConversationBaseRequest

- (nullable instancetype)init {
    ApptentiveAssertFail(@"Attempted to create an instance of ApptentiveConversationBaseRequest without specifying a conversation id");
    return nil;
}

- (nullable instancetype)initWithConversationId:( NSString * _Nonnull )conversationId {
    self = [super init];
    if (self) {
        ApptentiveAssertNotNil(conversationId, @"Conversation id is nil");
        if (conversationId == nil) {
            return nil;
        }
        _conversationId = [conversationId copy];
    }
    return self;
}

@end
