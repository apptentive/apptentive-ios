//
//  ApptentiveLogoutPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogoutPayload.h"


@implementation ApptentiveLogoutPayload

- (instancetype)initWithToken:(NSString *)token {
	self = [super init];

	if (self) {
		self.token = token;
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
	return @"conversations/<cid>/logout";
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.token };
}

@end
