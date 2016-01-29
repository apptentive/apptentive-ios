//
//  ATAppConfigurationUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/18/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATExpiringUpdater.h"

@class ATAppConfiguration;

extern NSString *const ATConfigurationSDKVersionKey;
extern NSString *const ATConfigurationAppBuildNumberKey;
extern NSString *const ATAppConfigurationExpirationPreferenceKey;

@interface ATAppConfigurationUpdater : ATExpiringUpdater

@property (readonly, nonatomic) ATAppConfiguration *appConfiguration;

@end
