//
//  ApptentiveLoginRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNewLoginRequest.h"
#import "ApptentiveDefines.h"


@implementation ApptentiveNewLoginRequest

- (instancetype)initWithToken:(NSString *)token {
	self = [super init];

	if (self) {
        APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(token);
		_token = token;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	return @"conversations";
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.token };
}


@end
