//
//  ATExpiry.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATExpiry.h"
#import "ATUtilities.h"
#import "ATConnect.h"

NSString *const ExpirationDateKey = @"expirationDate";
NSString *const SDKVersionKey = @"SDKVersion";
NSString *const AppBuildKey = @"appBuild";

@implementation ATExpiry

- (instancetype)initWithExpirationDate:(NSDate *)expirationDate appBuild:(NSString *)appBuild SDKVersion:(NSString *)SDKVersion {
	self = [super init];
	if (self) {
		_expirationDate = expirationDate;
		_SDKVersion = SDKVersion;
		_appBuild = appBuild;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super init];
	if (self) {
		_expirationDate = [coder decodeObjectForKey:ExpirationDateKey];
		_SDKVersion = [coder decodeObjectForKey:SDKVersionKey];
		_appBuild = [coder decodeObjectForKey:AppBuildKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.expirationDate forKey:ExpirationDateKey];
	[aCoder encodeObject:self.SDKVersion forKey:SDKVersionKey];
	[aCoder encodeObject:self.appBuild forKey:AppBuildKey];
}

- (BOOL)isExpired {
	return [self isExpiredForDate:[NSDate date] appBuild:[ATUtilities buildNumberString] SDKVersion:kATConnectVersionString];
}

- (BOOL)isExpiredForDate:(NSDate *)date appBuild:(NSString *)appBuild SDKVersion:(NSString *)SDKVersion {
	BOOL expired = [self.expirationDate timeIntervalSinceDate:date] <= 0;
	BOOL newAppBuild = ![appBuild isEqualToString:self.appBuild];
	BOOL newSDKVersion = ![SDKVersion isEqualToString:self.SDKVersion];

	return expired || newAppBuild || newSDKVersion;
}

@end
