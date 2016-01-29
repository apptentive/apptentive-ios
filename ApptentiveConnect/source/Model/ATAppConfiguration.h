//
//  ATAppConfiguration.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATUpdater.h"

extern NSString *const ATAppConfigurationAppDisplayNameKey;

@interface ATAppConfiguration : NSObject <ATUpdatable>

@property (readonly, nonatomic) NSString *creationSDKVersion;
@property (readonly, nonatomic) NSString *creationApplicationBuildNumber;
@property (readonly, nonatomic) BOOL metricsEnabled;
@property (readonly, nonatomic) BOOL hideBranding;
@property (readonly, nonatomic) BOOL notificationPopupsEnabled;
@property (readonly, nonatomic) NSTimeInterval messageCenterBackgroundPollingInterval;
@property (readonly, nonatomic) NSTimeInterval messageCenterForegroundPollingInterval;
@property (readonly, nonatomic) NSString *applicationDisplayName;

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary;
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;
+ (void)removeFromUserDefaults:(NSUserDefaults *)userDefaults;

@end
