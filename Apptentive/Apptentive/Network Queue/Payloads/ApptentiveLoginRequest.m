//
//  ApptentiveLoginRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLoginRequest.h"

@implementation ApptentiveLoginRequest

- (instancetype)initWithToken:(NSString *)token {
	self = [super init];

	if (self) {
		_token = token;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	return @"conversations/<cid>/session";
}

- (NSDictionary *)JSONDictionary {
	return  @{ @"token": self.token };
}


@end
