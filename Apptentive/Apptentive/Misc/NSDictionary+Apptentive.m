//
//  NSDictionary+ATAdditions.m
//  Apptentive
//
//  Created by Andrew Wooster on 2/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "NSDictionary+Apptentive.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSDictionary (Apptentive)

- (nullable id)at_safeObjectForKey:(id)aKey {
	id result = [self objectForKey:aKey];
	if (!result || [result isKindOfClass:[NSNull class]]) {
		return nil;
	}
	return result;
}

@end

NS_ASSUME_NONNULL_END
