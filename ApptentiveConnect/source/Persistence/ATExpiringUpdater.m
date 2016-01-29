//
//  ATExpiringUpdater.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/27/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATExpiringUpdater.h"
#import "ATUtilities.h"
#import "ATConnect.h"

@interface ATExpiringUpdater ()

@property (readonly, nonatomic) NSString *expiryStoragePath;

@end

@implementation ATExpiringUpdater

@synthesize expiry = _expiry;

- (BOOL)needsUpdate {
	return self.expiry.expired;
}

- (void)didUpdateWithRequest:(ATAPIRequest *)request {
	self.expiry.maxAge = request.expiresMaxAge;
}

#pragma mark - Expiry

- (NSString *)expiryStoragePath {
	return [self.storagePath stringByAppendingPathExtension:@".expiry"];
}

- (NSDate *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	return [NSDate distantPast];
}

- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	// Clean up legacy user defaults after migrating
}

- (void)setExpiry:(ATExpiry *)expiry {
	_expiry = expiry;

	[NSKeyedArchiver archiveRootObject:_expiry toFile:self.expiryStoragePath];
}

- (ATExpiry *)expiry {
	if (_expiry == nil) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.expiryStoragePath]) {
			_expiry = [NSKeyedUnarchiver unarchiveObjectWithFile:self.expiryStoragePath];
		} else if ([self expiryFromUserDefaults:[NSUserDefaults standardUserDefaults]]) {
			self.expiry = [self expiryFromUserDefaults:[NSUserDefaults standardUserDefaults]];
			[self removeExpiryFromUserDefaults:[NSUserDefaults standardUserDefaults]];
		} else {
			_expiry = [self emptyExpiry];
		}
	}

	return _expiry;
}

- (ATExpiry *)emptyExpiry {
	return nil;
}

@end

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
