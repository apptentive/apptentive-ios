//
//  ApptentiveConversationBaseRequest.m
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveConversationBaseRequest

@synthesize conversationIdentifier = _conversationIdentifier;

- (nullable instancetype)init {
	ApptentiveAssertFail(@"Attempted to create an instance of ApptentiveConversationBaseRequest without specifying a conversation id");
	return nil;
}

- (nullable instancetype)initWithConversationIdentifier:(NSString *_Nonnull)conversationIdentifier {
	self = [super init];
	if (self) {
		ApptentiveAssertNotNil(conversationIdentifier, @"Conversation identifier is nil");
		if (conversationIdentifier == nil) {
			return nil;
		}
		_conversationIdentifier = [conversationIdentifier copy];
	}
	return self;
}

@end

NS_ASSUME_NONNULL_END
