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
#import "ATExpiry.h"

@interface ATExpiringUpdater ()

@property (readonly, nonatomic) NSString *expiryStoragePath;

@end

@implementation ATExpiringUpdater

@synthesize expiry = _expiry;

- (BOOL)needsUpdate {
	return self.expiry == nil || self.expiry.expired;
}

- (void)didUpdateWithRequest:(ATAPIRequest *)request {
	[super didUpdateWithRequest:request];

	self.expiry = [[ATExpiry alloc] initWithExpirationDate:[NSDate dateWithTimeIntervalSinceNow:request.expiresMaxAge] appBuild:[ATUtilities buildNumberString] SDKVersion:kATConnectVersionString];
	[self archiveExpiry];
}

#pragma mark - Expiry

- (NSString *)expiryStoragePath {
	return [self.storagePath stringByAppendingPathExtension:@"expiry"];
}

- (ATExpiry *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	return nil;
}

- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	// Clean up legacy user defaults after migrating
}

- (ATExpiry *)expiry {
	if (_expiry == nil) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:self.expiryStoragePath]) {
			_expiry = [NSKeyedUnarchiver unarchiveObjectWithFile:self.expiryStoragePath];
		} else if ([self expiryFromUserDefaults:[NSUserDefaults standardUserDefaults]]) {
			_expiry = [self expiryFromUserDefaults:[NSUserDefaults standardUserDefaults]];
			[self removeExpiryFromUserDefaults:[NSUserDefaults standardUserDefaults]];
			[self archiveExpiry];
		} else {
			_expiry = [self emptyExpiry];
		}
	}

	return _expiry;
}

- (ATExpiry *)emptyExpiry {
	return [[ATExpiry alloc] initWithExpirationDate:[NSDate distantPast] appBuild:[ATUtilities buildNumberString] SDKVersion:kATConnectVersionString];
}

- (void)archiveExpiry {
	[NSKeyedArchiver archiveRootObject:_expiry toFile:self.expiryStoragePath];
}

@end
