//
//  ApptentiveLogoutPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogoutPayload.h"
#import "ApptentiveDefines.h"

@implementation ApptentiveLogoutPayload

- (instancetype)initWithConversationToken:(NSString *)token {
	self = [super init];

	if (self) {
        APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(token);
        _conversationToken = token;
	}

	return self;
}

- (NSString *)type {
	return @"logout";
}

- (NSString *)method {
	return @"DELETE";
}

- (NSString *)path {
	return @"conversations/<cid>/session";
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.conversationToken };
}

@end
