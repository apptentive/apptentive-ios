//
//  ApptentiveAppConfiguration.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApptentiveMessageCenterConfiguration : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSString *title;
@property (readonly, assign, nonatomic) NSTimeInterval foregroundPollingInterval;
@property (readonly, assign, nonatomic) NSTimeInterval backgroundPollingInterval;
@property (readonly, assign, nonatomic) BOOL emailRequired;
@property (readonly, assign, nonatomic) BOOL notificationPopupEnabled;

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary;
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

+ (void)deleteMigratedData;

@end

@interface ApptentiveAppConfiguration : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSString *supportDisplayName;
@property (readonly, strong, nonatomic) NSString *supportDisplayEmail;
@property (readonly, strong, nonatomic) NSURL *supportImageURL;

@property (readonly, assign, nonatomic) BOOL hideBranding;
@property (readonly, assign, nonatomic) BOOL messageCenterEnabled;
@property (readonly, assign, nonatomic) BOOL metricsEnabled;

@property (readonly, strong, nonatomic) ApptentiveMessageCenterConfiguration *messageCenter;

@property (strong, nonatomic) NSDate *expiry;

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime;
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

+ (void)deleteMigratedData;

@end
