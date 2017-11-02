//
//  ApptentiveDevice.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ATDeviceLastUpdateValuePreferenceKey;

@class ApptentiveVersion;


/**
 An `ApptentiveDevice` object stores data about the current device.
 */
@interface ApptentiveDevice : ApptentiveCustomData

/**
 A unique identifier that identifies the device. Set to the value of
 `UIDevice`'s `identifierForVendor` property.
 */
@property (readonly, strong, nonatomic) NSUUID *UUID;

/**
 The name of the operating system. Set to the value of `UIDevice`'s `systemName`
 property.
 */
@property (readonly, strong, nonatomic) NSString *OSName;

/**
 The version of the operating system. Initialized with the value of `UIDevice`'s
 `systemVersion` property.
 */
@property (readonly, strong, nonatomic) ApptentiveVersion *OSVersion;

/**
 The build of the operating system. Set to the value obtained from `sysctl`'s
 `KERN_OSVERSION` field.
 */
@property (readonly, strong, nonatomic) NSString *OSBuild;

/**
 The hardware the device is running on. Set to the value of the `machine` field
 returned from `uname`. For example, "iPhone9,4".
 */
@property (readonly, strong, nonatomic) NSString *hardware;

/**
 The mobile phone network carrier the device is associated with, if any. Set to
 Set to the value of the `carrierName` property of the
 `subscriberCellularProvider`property of the `CTTelephonyNetworkInfo` object.
 */
@property (readonly, strong, nonatomic) NSString *carrier;

/**
 The content size category (text size) set on the device. Set to the value of
 the `preferredContentSizeCategory` property of the `UIApplication` singleton.
 */
@property (readonly, strong, nonatomic) NSString *contentSizeCategory;

/**
 The raw locale string for the device. For example "en_US".
 */
@property (readonly, strong, nonatomic) NSString *localeRaw;

/**
 The country code from the device's locale. For example "US".
 */
@property (readonly, strong, nonatomic) NSString *localeCountryCode;

/**
 The language code from device's locale. For example "en".
 */
@property (readonly, strong, nonatomic) NSString *localeLanguageCode;

/**
 The number of seconds that the device's time zone is offset from UTC. Set
 to the value returned from `NSTimeZone`'s `secondsFromGMT` property. */
@property (readonly, assign, nonatomic) NSInteger UTCOffset;

/**
 The integrations that have been configured for the device. Typically this
 may contain information related to push notification provider, such as the
 device token used for push notifications.
 */
@property (copy, nonatomic) NSDictionary *integrationConfiguration;

/**
 Initializes a device object with values obtained from the current device.

 @return The newly-initialized device object.
 */
- (instancetype)initWithCurrentDevice;

/**
 Updates the device object with values from the current environment.
 */
- (void)updateWithCurrentDeviceValues;

/**
 Sets static variables for the values that won't change until app is terminated.
 */
+ (void)getPermanentDeviceValues;

/**
 The push integration to be set globally for all devices
 */
@property (class, strong, nonatomic) NSDictionary *integrationConfiguration;

/**
 Due to threading issues, we need to determine carrier on the main thread.
 This is an intermediate value that device objects can use to update themselves.
 */
@property (class, strong, nonatomic) NSString *carrierName;

/**
 Due to UIKit thread safety issues, we need to determine this on the main thread.
 This is an intermediate value that device objects can use to update themselves.
 */
@property (class, strong, nonatomic) UIContentSizeCategory contentSizeCategory;

@end

NS_ASSUME_NONNULL_END
