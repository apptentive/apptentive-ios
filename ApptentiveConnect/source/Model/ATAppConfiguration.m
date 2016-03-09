//
//  ATAppConfiguration.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATAppConfiguration.h"
#import "ATConnect.h"
#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"
#import "ATAppConfigurationUpdater.h"

// JSON + NSCoding keys
NSString *const applicationDisplayNameKey = @"app_display_name";
NSString *const metricsEnabledKey = @"metrics_enabled";
NSString *const hideBrandingKey = @"hide_branding";
NSString *const messageCenterKey = @"message_center";
NSString *const foregroundPollingIntervalKey = @"fg_poll";
NSString *const backgroundPollingIntervalKey = @"bg_poll";
NSString *const notificationPopupKey = @"notification_popup";
NSString *const enabledKey = @"enabled";

// NSCoding keys
NSString *const creationSDKVersionKey = @"created_sdk_version";
NSString *const creationApplicationBuildNumberKey = @"created_app_build_number";
NSString *const messageCenterForegroundPollingIntervalKey = @"message_center_fg_poll";
NSString *const messageCenterBackgroundPollingIntervalKey = @"message_center_bg_poll";
NSString *const notificationPopupsEnabledKey = @"notification_popups_enabled";

// Legacy NSUserDefaults keys
NSString *const ATAppConfigurationMetricsEnabledPreferenceKey = @"ATAppConfigurationMetricsEnabledPreferenceKey";
NSString *const ATAppConfigurationHideBrandingKey = @"ATAppConfigurationHideBrandingKey";
NSString *const ATAppConfigurationNotificationPopupsEnabledKey = @"ATAppConfigurationNotificationPopupsEnabledKey";
NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterForegroundRefreshIntervalKey";
NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey";
NSString *const ATAppConfigurationAppDisplayNameKey = @"ATAppConfigurationAppDisplayNameKey";

@implementation ATAppConfiguration

+ (instancetype)newInstanceFromDictionary:(NSDictionary *)dictionary {
	return [[self alloc] initWithJSONDictionary:dictionary];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary {
	self = [self init];
	if (self) {
		if ([[JSONDictionary objectForKey:applicationDisplayNameKey] isKindOfClass:[NSString class]]) {
			_applicationDisplayName = [JSONDictionary objectForKey:applicationDisplayNameKey];
		}

		if ([[JSONDictionary objectForKey:metricsEnabledKey] isKindOfClass:[NSNumber class]]) {
			_metricsEnabled = [[JSONDictionary objectForKey:metricsEnabledKey] boolValue];
		}

		if ([[JSONDictionary objectForKey:hideBrandingKey] isKindOfClass:[NSNumber class]]) {
			_hideBranding = [[JSONDictionary objectForKey:hideBrandingKey] boolValue];
		}

		if ([[JSONDictionary objectForKey:messageCenterKey] isKindOfClass:[NSDictionary class]]) {
			NSDictionary *messageCenterDictionary = [JSONDictionary objectForKey:messageCenterKey];

			if ([[messageCenterDictionary objectForKey:foregroundPollingIntervalKey] isKindOfClass:[NSNumber class]]) {
				_messageCenterForegroundPollingInterval = [[messageCenterDictionary objectForKey:foregroundPollingIntervalKey] doubleValue];
			}

			if ([[messageCenterDictionary objectForKey:backgroundPollingIntervalKey] isKindOfClass:[NSNumber class]]) {
				_messageCenterBackgroundPollingInterval = [[messageCenterDictionary objectForKey:backgroundPollingIntervalKey] doubleValue];
			}

			if ([[messageCenterDictionary objectForKey:notificationPopupKey] isKindOfClass:[NSDictionary class]]) {
				NSDictionary *notificationPopupDictionary = [messageCenterDictionary objectForKey:notificationPopupKey];

				if ([[notificationPopupDictionary objectForKey:enabledKey] isKindOfClass:[NSNumber class]]) {
					_notificationPopupsEnabled = [[notificationPopupDictionary objectForKey:enabledKey] boolValue];
				}
			}
		}
	}
	return self;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_creationSDKVersion = kATConnectVersionString;
		_creationApplicationBuildNumber = [ATUtilities buildNumberString];

		_metricsEnabled = YES;
		_hideBranding = NO;
		
		_messageCenterForegroundPollingInterval = 8.0;
		_messageCenterBackgroundPollingInterval = 60.0;

		_notificationPopupsEnabled = NO;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];

	if (self) {
		_creationSDKVersion = [aDecoder decodeObjectForKey:creationSDKVersionKey];
		_creationApplicationBuildNumber = [aDecoder decodeObjectForKey:creationApplicationBuildNumberKey];

		_applicationDisplayName = [aDecoder decodeObjectForKey:applicationDisplayNameKey];
		_metricsEnabled = [aDecoder decodeBoolForKey:metricsEnabledKey];
		_hideBranding = [aDecoder decodeBoolForKey:hideBrandingKey];

		_messageCenterForegroundPollingInterval = [aDecoder decodeDoubleForKey:messageCenterForegroundPollingIntervalKey];
		_messageCenterBackgroundPollingInterval = [aDecoder decodeDoubleForKey:messageCenterBackgroundPollingIntervalKey];

		_notificationPopupsEnabled = [aDecoder decodeBoolForKey:notificationPopupsEnabledKey];
	}

	return self;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
	self = [super init];

	if (self) {
		_creationSDKVersion = [userDefaults objectForKey:ATConfigurationSDKVersionKey];
		_creationApplicationBuildNumber = [userDefaults objectForKey:ATConfigurationAppBuildNumberKey];

		_applicationDisplayName = [userDefaults stringForKey:ATAppConfigurationAppDisplayNameKey];
		_metricsEnabled = [userDefaults boolForKey:ATAppConfigurationMetricsEnabledPreferenceKey];
		_hideBranding = [userDefaults boolForKey:ATAppConfigurationHideBrandingKey];

		NSNumber *foregroundPollingInterval = [userDefaults objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
		if (foregroundPollingInterval) {
			_messageCenterForegroundPollingInterval = [foregroundPollingInterval doubleValue];
		}

		NSNumber *backgroundPollingInterval = [userDefaults objectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
		if (backgroundPollingIntervalKey) {
			_messageCenterBackgroundPollingInterval = [backgroundPollingInterval doubleValue];
		}

		_notificationPopupsEnabled = [userDefaults boolForKey:ATAppConfigurationNotificationPopupsEnabledKey];
	}
	return self;
}

+ (void)removeFromUserDefaults:(NSUserDefaults *)userDefaults {
	NSArray *keys = @[
					  ATConfigurationSDKVersionKey,
					  ATConfigurationAppBuildNumberKey,
					  ATAppConfigurationExpirationPreferenceKey,
					  ATAppConfigurationMetricsEnabledPreferenceKey,
					  ATAppConfigurationHideBrandingKey,
					  ATAppConfigurationNotificationPopupsEnabledKey,
					  ATAppConfigurationMessageCenterForegroundRefreshIntervalKey,
					  ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey,
					  ATAppConfigurationAppDisplayNameKey
					  ];

	for (NSString *key in keys) {
		[userDefaults removeObjectForKey:key];
	}
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:self.creationSDKVersion forKey:creationSDKVersionKey];
	[coder encodeObject:self.creationApplicationBuildNumber forKey:creationApplicationBuildNumberKey];

	[coder encodeObject:self.applicationDisplayName forKey:applicationDisplayNameKey];
	[coder encodeBool:self.metricsEnabled forKey:metricsEnabledKey];
	[coder encodeBool:self.hideBranding forKey:hideBrandingKey];

	[coder encodeDouble:self.messageCenterForegroundPollingInterval forKey:messageCenterForegroundPollingIntervalKey];
	[coder encodeDouble:self.messageCenterBackgroundPollingInterval forKey:messageCenterBackgroundPollingIntervalKey];

	[coder encodeBool:self.notificationPopupsEnabled forKey:notificationPopupsEnabledKey];
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) return NO;
	ATAppConfiguration *other = (ATAppConfiguration *)object;

	if (self.metricsEnabled != other.metricsEnabled) return NO;
	if (self.hideBranding != other.hideBranding) return NO;
	if (self.notificationPopupsEnabled != other.notificationPopupsEnabled) return NO;
	if (self.messageCenterForegroundPollingInterval != other.messageCenterForegroundPollingInterval) return NO;
	if (self.messageCenterBackgroundPollingInterval != other.messageCenterBackgroundPollingInterval) return NO;
	if (![self.applicationDisplayName isEqualToString:other.applicationDisplayName]) return NO;

	return YES;
}

// This is not really used, but included for completeness with the ATUpdatable protocol
- (NSDictionary *)dictionaryRepresentation {
	return @{
		@"app_display_name": self.applicationDisplayName,
		@"metrics_enabled": @(self.metricsEnabled),
		@"hide_branding": @(self.hideBranding),
		@"message_center": @{
			 @"fg_poll": @(self.messageCenterForegroundPollingInterval),
			 @"bg_poll": @(self.messageCenterBackgroundPollingInterval),
			 @"notification_popup": @{
						@"enabled": @(self.notificationPopupsEnabled)
					 },
			 },
		};
}

@end
