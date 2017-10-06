//
//  ApptentiveExistingLoginRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveExistingLoginRequest.h"
#import "ApptentiveAppInstall.h"
#import "ApptentiveDefines.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveExistingLoginRequest

- (nullable instancetype)initWithAppInstall:(id<ApptentiveAppInstall>)appInstall {
	APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(appInstall.token);
	APPTENTIVE_CHECK_INIT_NOT_EMPTY_ARG(appInstall.identifier);

	return [super initWithAppInstall:appInstall];
}

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/%@/session", self.appInstall.identifier];
}

- (NSDictionary *)JSONDictionary {
	return @{ @"token": self.appInstall.token };
}

@end

NS_ASSUME_NONNULL_END
