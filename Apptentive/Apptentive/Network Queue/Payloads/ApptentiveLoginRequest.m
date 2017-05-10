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
		if (conversationIdentifier.length == 0) {
			ApptentiveLogError(@"Unable to create %@: conversation identifier is nil or empty", [self class]);
			return nil;
		}

		if (token.length == 0) {
			ApptentiveLogError(@"Unable to create %@: conversation token is nil or empty", [self class]);
			return nil;
		}

		_conversationIdentifier = conversationIdentifier;
		_token = token;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/%@/session", self.conversationIdentifier];
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.token };
}


@end
