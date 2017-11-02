//
//  ApptentiveAppConfiguration.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppConfiguration.h"
#import "ApptentiveDefines.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const SupportDisplayNameKey = @"supportDisplayName";
static NSString *const SupportDisplayEmailKey = @"supportDisplayEmail";
static NSString *const SupportImageURLKey = @"supportImageURL";
static NSString *const HideBrandingKey = @"hideBranding";
static NSString *const MessageCenterEnabledKey = @"messageCenterEnabled";
static NSString *const MetricsEnabledKey = @"metricsEnabled";
static NSString *const MessageCenterKey = @"messageCenter";
static NSString *const ExpiryKey = @"expiry";

static NSString *const TitleKey = @"title";
static NSString *const ForegroundPollingIntervalKey = @"foregroundPollingInterval";
static NSString *const BackgroundPollingIntervalKey = @"backgroundPollingInterval";
static NSString *const EmailRequiredKey = @"emailRequired";
static NSString *const NotificationPopupEnabledKey = @"notificationPopupEnabled";

// Legacy keys
static NSString *const ATAppConfigurationMetricsEnabledPreferenceKey = @"ATAppConfigurationMetricsEnabledPreferenceKey";
static NSString *const ATAppConfigurationHideBrandingKey = @"ATAppConfigurationHideBrandingKey";
static NSString *const ATAppConfigurationExpirationPreferenceKey = @"ATAppConfigurationExpirationPreferenceKey";
static NSString *const ATAppConfigurationNotificationPopupsEnabledKey = @"ATAppConfigurationNotificationPopupsEnabledKey";
static NSString *const ATAppConfigurationMessageCenterForegroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterForegroundRefreshIntervalKey";
static NSString *const ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey = @"ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey";


@implementation ApptentiveAppConfiguration

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_metricsEnabled = YES;
		_expiry = [NSDate distantPast];

		_messageCenter = [[ApptentiveMessageCenterConfiguration alloc] init];
	}

	return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime {
	self = [self init];

	if (self) {
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(JSONDictionary);

		_supportDisplayName = JSONDictionary[@"support_display_name"];
		_supportDisplayEmail = JSONDictionary[@"support_display_email"];

		NSString *supportImageURLString = JSONDictionary[@"support_image_url"];
		if (supportImageURLString) {
			_supportImageURL = [NSURL URLWithString:supportImageURLString];
		}

		_hideBranding = [JSONDictionary[@"hide_branding"] boolValue];
		_messageCenterEnabled = [JSONDictionary[@"message_center_enabled"] boolValue];
		_metricsEnabled = [JSONDictionary[@"metrics_enabled"] boolValue];

		_messageCenter = [[ApptentiveMessageCenterConfiguration alloc] initWithJSONDictionary:JSONDictionary[@"message_center"]];

		_expiry = [NSDate dateWithTimeIntervalSinceNow:cacheLifetime];
	}

	return self;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
	self = [self init];

	if (self) {
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(userDefaults);

		_metricsEnabled = [userDefaults boolForKey:ATAppConfigurationMetricsEnabledPreferenceKey];
		_hideBranding = [userDefaults boolForKey:ATAppConfigurationHideBrandingKey];

		_messageCenter = [[ApptentiveMessageCenterConfiguration alloc] initWithUserDefaults:userDefaults];

		_expiry = [userDefaults objectForKey:ATAppConfigurationExpirationPreferenceKey];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationExpirationPreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationMetricsEnabledPreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationHideBrandingKey];

	[ApptentiveMessageCenterConfiguration deleteMigratedData];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_supportDisplayName = [coder decodeObjectOfClass:[NSString class] forKey:SupportDisplayNameKey];
		_supportDisplayEmail = [coder decodeObjectOfClass:[NSString class] forKey:SupportDisplayEmailKey];
		_supportImageURL = [coder decodeObjectOfClass:[NSURL class] forKey:SupportImageURLKey];
		_hideBranding = [coder decodeBoolForKey:HideBrandingKey];
		_messageCenterEnabled = [coder decodeBoolForKey:MessageCenterEnabledKey];
		_metricsEnabled = [coder decodeBoolForKey:MetricsEnabledKey];
		_messageCenter = [coder decodeObjectOfClass:[ApptentiveMessageCenterConfiguration class] forKey:MessageCenterKey];
		_expiry = [coder decodeObjectOfClass:[NSDate class] forKey:ExpiryKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.supportDisplayName forKey:SupportDisplayNameKey];
	[coder encodeObject:self.supportDisplayEmail forKey:SupportDisplayEmailKey];
	[coder encodeObject:self.supportImageURL forKey:SupportImageURLKey];
	[coder encodeBool:self.hideBranding forKey:HideBrandingKey];
	[coder encodeBool:self.messageCenterEnabled forKey:MessageCenterEnabledKey];
	[coder encodeBool:self.metricsEnabled forKey:MetricsEnabledKey];
	[coder encodeObject:self.messageCenter forKey:MessageCenterKey];
	[coder encodeObject:self.expiry forKey:ExpiryKey];
}

@end


@implementation ApptentiveMessageCenterConfiguration

@synthesize foregroundPollingInterval = _foregroundPollingInterval;
@synthesize backgroundPollingInterval = _backgroundPollingInterval;

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_foregroundPollingInterval = 20;
		_backgroundPollingInterval = 60;
		_notificationPopupEnabled = NO;
	}

	return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary {
	self = [self init];

	if (![JSONDictionary isKindOfClass:[NSDictionary class]]) {
		return nil;
	}

	if (self) {
		_title = JSONDictionary[@"title"];
		_foregroundPollingInterval = [JSONDictionary[@"fg_poll"] doubleValue];
		_backgroundPollingInterval = [JSONDictionary[@"bg_poll"] doubleValue];
		_emailRequired = [JSONDictionary[@"email_required"] boolValue];
		_notificationPopupEnabled = [JSONDictionary[@"notification_popup"][@"enabled"] boolValue];
	}

	return self;
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
	self = [self init];

	if (self) {
		_notificationPopupEnabled = [userDefaults boolForKey:ATAppConfigurationNotificationPopupsEnabledKey];
		_foregroundPollingInterval = [[userDefaults objectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey] doubleValue];
		_backgroundPollingInterval = [[userDefaults objectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey] doubleValue];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationNotificationPopupsEnabledKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationMessageCenterForegroundRefreshIntervalKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATAppConfigurationMessageCenterBackgroundRefreshIntervalKey];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_title = [coder decodeObjectOfClass:[NSString class] forKey:TitleKey];
		_foregroundPollingInterval = [coder decodeDoubleForKey:ForegroundPollingIntervalKey];
		_backgroundPollingInterval = [coder decodeDoubleForKey:BackgroundPollingIntervalKey];
		_emailRequired = [coder decodeBoolForKey:EmailRequiredKey];
		_notificationPopupEnabled = [coder decodeBoolForKey:NotificationPopupEnabledKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.title forKey:TitleKey];
	[coder encodeDouble:self.foregroundPollingInterval forKey:ForegroundPollingIntervalKey];
	[coder encodeDouble:self.backgroundPollingInterval forKey:BackgroundPollingIntervalKey];
	[coder encodeBool:self.emailRequired forKey:EmailRequiredKey];
	[coder encodeBool:self.notificationPopupEnabled forKey:NotificationPopupEnabledKey];
}


- (NSTimeInterval)foregroundPollingInterval {
	return fmax(_foregroundPollingInterval, 4.0);
}

- (NSTimeInterval)backgroundPollingInterval {
	return fmax(_backgroundPollingInterval, 30.0);
}

@end

NS_ASSUME_NONNULL_END
