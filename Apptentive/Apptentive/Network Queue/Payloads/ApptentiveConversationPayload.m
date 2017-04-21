//
//  ApptentiveConversationPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationPayload.h"
#import "ApptentiveConversation.h"

@implementation ApptentiveConversationPayload

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation {
	self = [super init];

	if (self) {
		_conversation = conversation;
	}

	return self;
}

- (NSString *)path {
	return @"conversation";
}

- (NSString *)method {
	return @"PUT";
}

- (NSDictionary *)JSONDictionary {
	return self.conversation.conversationUpdateJSON;
}

@end
