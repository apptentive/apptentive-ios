//
//  ApptentiveLoginRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLoginRequest.h"


@implementation ApptentiveLoginRequest

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier token:(NSString *)token {
	self = [super init];

	if (self) {
		_conversationIdentifier = conversationIdentifier;
		_token = token;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	if (self.conversationIdentifier != nil) {
		return [NSString stringWithFormat:@"conversations/%@/session", self.conversationIdentifier];
	} else {
		return @"conversations";
	}
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.token };
}


@end
