//
//  ApptentiveLogoutPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLogoutPayload.h"
#import "ApptentiveDefines.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveLogoutPayload

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
	return @{};
}

@end

NS_ASSUME_NONNULL_END
