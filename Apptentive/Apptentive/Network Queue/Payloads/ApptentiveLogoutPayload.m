//
//  ApptentiveLogoutPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogoutPayload.h"

@implementation ApptentiveLogoutPayload

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier Token:(NSString *)token {
	self = [super init];

	if (self) {
		_conversationIdentifier = conversationIdentifier;
		_token = token;
	}

	return self;
}

- (NSString *)path {
	return [NSString stringWithFormat:@"/conversations/%@/logout", self.conversationIdentifier];
}

- (NSDictionary *)JSONDictionary {
	return  @{ @"token": self.token, @"logout": @{} };
}

@end
