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

NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
NSString *const ATConfigurationSDKVersionKey = @"ATConfigurationSDKVersionKey";
NSString *const ATConfigurationAppBuildNumberKey = @"ATConfigurationAppBuildNumberKey";

@implementation ATAppConfigurationUpdater

+ (Class<ATUpdatable>)updatableClass {
	return [ATAppConfiguration class];
}

- (ATExpiry *)expiryFromUserDefaults:(NSUserDefaults *)userDefaults {
	return [[ATExpiry alloc] initWithExpirationDate:[userDefaults objectForKey:ATAppConfigurationExpirationPreferenceKey] appBuild:[userDefaults objectForKey:ATConfigurationAppBuildNumberKey] SDKVersion:[userDefaults objectForKey:ATConfigurationSDKVersionKey]];
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

@end
