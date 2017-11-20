//
//  ApptentiveDevice.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDevice.h"
#import "ApptentiveVersion.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>
#include <stdlib.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const UUIDKey = @"UUID";
static NSString *const OSNameKey = @"OSName";
static NSString *const OSVersionKey = @"OSVersion";
static NSString *const OSBuildKey = @"OSBuild";
static NSString *const HardwareKey = @"hardware";
static NSString *const CarrierKey = @"carrier";
static NSString *const ContentSizeCategoryKey = @"contentSizeCategory";
static NSString *const LocaleRawKey = @"localeRaw";
static NSString *const LocaleCountryCodeKey = @"localeCountryCode";
static NSString *const LocaleLanguageCodeKey = @"localeLanguageCode";
static NSString *const UTCOffsetKey = @"UTCOffset";
static NSString *const IntegrationConfigurationKey = @"integrationConfiguration";

// Legacy keys
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";
static NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
static NSString *const ApptentiveCustomDeviceDataPreferenceKey = @"ApptentiveCustomDeviceDataPreferenceKey";

static NSUUID *_currentUUID;
static NSString *_currentOSName;
static ApptentiveVersion *_currentOSVersion;
static NSString *_currentOSBuild;
static NSString *_currentHardware;

static NSDictionary *_currentIntegrationConfiguration;
static NSString *_currentCarrierName;
static UIContentSizeCategory _currentContentSizeCategory;


@implementation ApptentiveDevice

+ (void)setIntegrationConfiguration:(NSDictionary *)integrationConfiguration {
	_currentIntegrationConfiguration = integrationConfiguration;
}

+ (NSDictionary *)integrationConfiguration {
	return _currentIntegrationConfiguration;
}

+ (void)setCarrierName:(NSString *)carrierName {
	_currentCarrierName = carrierName;
}

+ (NSString *)carrierName {
	return _currentCarrierName;
}

+ (void)setContentSizeCategory:(UIContentSizeCategory)contentSizeCategory {
	_currentContentSizeCategory = contentSizeCategory;
}

+ (UIContentSizeCategory)contentSizeCategory {
	return _currentContentSizeCategory;
}

+ (void)getPermanentDeviceValues {
	_currentUUID = [UIDevice currentDevice].identifierForVendor;
	_currentOSName = [UIDevice currentDevice].systemName;
	_currentOSVersion = [[ApptentiveVersion alloc] initWithString:[UIDevice currentDevice].systemVersion];

	int mib[2] = {CTL_KERN, KERN_OSVERSION};
	size_t size = 0;
	sysctl(mib, 2, NULL, &size, NULL, 0);
	char *answer = malloc(size);
	int result = sysctl(mib, 2, answer, &size, NULL, 0);
	if (result >= 0) {
		_currentOSBuild = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	}
	free(answer);

	struct utsname systemInfo;
	uname(&systemInfo);
	_currentHardware = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_integrationConfiguration = @{};
	}

	return self;
}

- (instancetype)initWithCurrentDevice {
	self = [self init];

	if (self) {
		[self updateWithCurrentDeviceValues];
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_UUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:UUIDKey];
		_OSName = [aDecoder decodeObjectOfClass:[NSString class] forKey:OSNameKey];
		_OSVersion = [aDecoder decodeObjectOfClass:[ApptentiveVersion class] forKey:OSVersionKey];
		_OSBuild = [aDecoder decodeObjectOfClass:[NSString class] forKey:OSBuildKey];
		_hardware = [aDecoder decodeObjectOfClass:[NSString class] forKey:HardwareKey];
		_carrier = [aDecoder decodeObjectOfClass:[NSString class] forKey:CarrierKey];
		_contentSizeCategory = [aDecoder decodeObjectOfClass:[NSString class] forKey:ContentSizeCategoryKey];
		_localeRaw = [aDecoder decodeObjectOfClass:[NSString class] forKey:LocaleRawKey];
		_localeCountryCode = [aDecoder decodeObjectOfClass:[NSString class] forKey:LocaleCountryCodeKey];
		_localeLanguageCode = [aDecoder decodeObjectOfClass:[NSString class] forKey:LocaleLanguageCodeKey];
		_UTCOffset = [aDecoder decodeIntegerForKey:UTCOffsetKey];
		_integrationConfiguration = [aDecoder decodeObjectOfClass:[NSDictionary class] forKey:IntegrationConfigurationKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:self.UUID forKey:UUIDKey];
	[aCoder encodeObject:self.OSName forKey:OSNameKey];
	[aCoder encodeObject:self.OSVersion forKey:OSVersionKey];
	[aCoder encodeObject:self.OSBuild forKey:OSBuildKey];
	[aCoder encodeObject:self.hardware forKey:HardwareKey];
	[aCoder encodeObject:self.carrier forKey:CarrierKey];
	[aCoder encodeObject:self.contentSizeCategory forKey:ContentSizeCategoryKey];
	[aCoder encodeObject:self.localeRaw forKey:LocaleRawKey];
	[aCoder encodeObject:self.localeCountryCode forKey:LocaleCountryCodeKey];
	[aCoder encodeObject:self.localeLanguageCode forKey:LocaleLanguageCodeKey];
	[aCoder encodeInteger:self.UTCOffset forKey:UTCOffsetKey];
	[aCoder encodeObject:self.integrationConfiguration forKey:IntegrationConfigurationKey];
}

- (instancetype)initAndMigrate {
	NSDictionary *customData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ApptentiveCustomDeviceDataPreferenceKey];
	NSDictionary *device = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey] valueForKey:@"device"];

	if (customData == nil) {
		customData = device[@"custom_data"];
	}

	self = [super initWithCustomData:customData];

	if (device) {
		_integrationConfiguration = device[@"integration_config"];
		[[self class] setIntegrationConfiguration:self.integrationConfiguration];
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATDeviceLastUpdateValuePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATDeviceLastUpdatePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ApptentiveCustomDeviceDataPreferenceKey];
}

#pragma mark - Private

- (void)updateWithCurrentDeviceValues {
	_UUID = _currentUUID;
	_OSName = _currentOSName;
	_OSVersion = _currentOSVersion;
	_OSBuild = _currentOSBuild;
	_hardware = _currentHardware;

	_carrier = [self class].carrierName;
	_contentSizeCategory = [self class].contentSizeCategory;

	_localeRaw = [NSLocale currentLocale].localeIdentifier;
	NSDictionary *localeComponents = [NSLocale componentsFromLocaleIdentifier:[NSLocale currentLocale].localeIdentifier];
	_localeCountryCode = [localeComponents objectForKey:NSLocaleCountryCode];
	_localeLanguageCode = [NSBundle mainBundle].preferredLocalizations.firstObject;
	_UTCOffset = [NSTimeZone systemTimeZone].secondsFromGMT;

	_integrationConfiguration = ApptentiveDevice.integrationConfiguration;
}

@end


@implementation ApptentiveDevice (JSON)

- (NSNumber *)boxedUTCOffset {
	return @(self.UTCOffset);
}

- (NSString *)UUIDString {
	return self.UUID.UUIDString;
}

- (NSString *)OSVersionString {
	return self.OSVersion.versionString;
}

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"custom_data": NSStringFromSelector(@selector(customData)),
		@"uuid": NSStringFromSelector(@selector(UUIDString)),
		@"os_name": NSStringFromSelector(@selector(OSName)),
		@"os_version": NSStringFromSelector(@selector(OSVersionString)),
		@"os_build": NSStringFromSelector(@selector(OSBuild)),
		@"hardware": NSStringFromSelector(@selector(hardware)),
		@"carrier": NSStringFromSelector(@selector(carrier)),
		@"content_size_category": NSStringFromSelector(@selector(contentSizeCategory)),
		@"locale_raw": NSStringFromSelector(@selector(localeRaw)),
		@"locale_country_code": NSStringFromSelector(@selector(localeCountryCode)),
		@"locale_language_code": NSStringFromSelector(@selector(localeLanguageCode)),
		@"utc_offset": NSStringFromSelector(@selector(boxedUTCOffset)),
		@"integration_config": NSStringFromSelector(@selector(integrationConfiguration))
	};
}

@end

NS_ASSUME_NONNULL_END
