//
//  ApptentiveAppConfiguration.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An `ApptentiveMessageCenterConfiguration` represents the Message Center
 section of data downloaded from the `/conversation/configuration` endpoint
 on the Apptentive server API.
 */
@interface ApptentiveMessageCenterConfiguration : NSObject <NSSecureCoding>

/**
 The title to use for Message Center. (This appears to be no longer used.)
 */
@property (readonly, strong, nonatomic) NSString *title;

/**
 The (inverse) frequency to check for new messages when Message Center is
 visible.
 */
@property (readonly, assign, nonatomic) NSTimeInterval foregroundPollingInterval;

/**
 The (inverse) frequency to check for new messages when Message Center is not
 visible.
 */
@property (readonly, assign, nonatomic) NSTimeInterval backgroundPollingInterval;

/**
 Whether Message Center should require an email address.
 (appears to no longer be used.)
 */
@property (readonly, assign, nonatomic) BOOL emailRequired;


/**
 Whether in-app notification banners should be used when a new message is 
 downloaded.
 */
@property (readonly, assign, nonatomic) BOOL notificationPopupEnabled;


/**
 Initializes a Message Center configuration object using JSON downloaded from
 the `/conversation/configuration` endpoint of the Apptentive server API.

 @param JSONDictionary A dictionary decoded from the downloaded JSON.
 @return The newly-initialized message center configuration object.
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary;

/**
 Migrates a legacy Message Center configuration from `NSUserDefaults`

 @param userDefaults The `NSUserDefaults` instance from which to migrate (used
 for testing).
 @return The newly-migrated message center configuration object.
 */
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

/**
 Deletes the data migrated from `NSUserDefaults`.
 */
+ (void)deleteMigratedData;

@end


/**
 An `ApptentiveAppConfiguration` object represents the data downloaded from
 the `/conversation/configuration` endpoint on the Apptentive server API.
 */
@interface ApptentiveAppConfiguration : NSObject <NSSecureCoding>


/**
 The display name to use for the support user.
 */
@property (readonly, strong, nonatomic) NSString *supportDisplayName;

/**
 The email to use for the support user.
 */
@property (readonly, strong, nonatomic) NSString *supportDisplayEmail;

/**
 The image URL to use for the support user avatar.
 */
@property (readonly, strong, nonatomic) NSURL *supportImageURL;

/**
 Whether to hide the Apptentive branding in the SDK. (This is no longer used.)
 */
@property (readonly, assign, nonatomic) BOOL hideBranding;


/**
 Whether message center is enabled. (This is now configured with the Message
 Center interaction.)
 */
@property (readonly, assign, nonatomic) BOOL messageCenterEnabled;

/**
 Whether metrics (events) should be sent to the Apptentive server.
 */
@property (readonly, assign, nonatomic) BOOL metricsEnabled;

/**
 The configuration for Message Center (see
 `ApptentiveMessageCenterConfiguration`).
 */
@property (readonly, strong, nonatomic) ApptentiveMessageCenterConfiguration *messageCenter;

/**
 The date after which the app configuration is no longer considered up-to-date.
 */
@property (strong, nonatomic) NSDate *expiry;

/**
 Creates a new app configuration object based on the JSON downloaded from the
 `/conversation/configuration` endpoint of the Apptentive server API.

 @param JSONDictionary A dictionary decoded from the transmitted JSON
 @param cacheLifetime The number of seconds for which the configuration is
 considered up-to-date.
 @return The newly-initialized app confguration object.
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime;

/**
 Migrates legacy app configuration from `NSUserDefaults`.

 @param userDefaults The `NSUserDefaults` instance from which to migrate (used
 for testing).
 @return The newly-migrated app configuration object.
 */
- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

/**
 Deletes the data migrated from `NSUserDefaults`.
 */
+ (void)deleteMigratedData;

@end

NS_ASSUME_NONNULL_END
