//
//  ATAppConfigurationUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfigurationUpdater.h"
#import "ATAppConfiguration.h"
#import "ATWebClient.h"
#import "ATConnect_Private.h"
#import "ATExpiry.h"

NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
NSString *const ATConfigurationSDKVersionKey = @"ATConfigurationSDKVersionKey";
NSString *const ATConfigurationAppBuildNumberKey = @"ATConfigurationAppBuildNumberKey";

@implementation ATAppConfigurationUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATAppConfiguration class];
}

- (ATExpiry *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSDate *expirationDate = [userDefaults objectForKey:ATAppConfigurationExpirationPreferenceKey];
	NSString *appBuild = [userDefaults objectForKey:ATConfigurationAppBuildNumberKey];
	NSString *SDKVersion = [userDefaults objectForKey:ATConfigurationSDKVersionKey];

	if (expirationDate || appBuild || SDKVersion) {
		return [[ATExpiry alloc] initWithExpirationDate:expirationDate ?: [NSDate distantPast] appBuild:appBuild SDKVersion:SDKVersion];
	} else {
		return nil;
	}
}

- (void)removeExpiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	[userDefaults removeObjectForKey:ATAppConfigurationExpirationPreferenceKey];
	[userDefaults removeObjectForKey:ATConfigurationAppBuildNumberKey];
	[userDefaults removeObjectForKey:ATConfigurationSDKVersionKey];
}

- (id<ATUpdatable>)currentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	return [[ATAppConfiguration alloc] initWithUserDefaults:userDefaults];
}

- (void)removeCurrentVersionFromUserDefaults:(NSUserDefaults *)userDefaults {
	[ATAppConfiguration removeFromUserDefaults:userDefaults];
}

- (id<ATUpdatable>)emptyCurrentVersion {
	return [[ATAppConfiguration alloc] init];
}

- (ATAPIRequest *)requestForUpdating {
	return [[ATConnect sharedConnection].webClient requestForGettingAppConfiguration];
}

- (ATAppConfiguration *)appConfiguration {
	return (ATAppConfiguration *)self.currentVersion;
}

@end
