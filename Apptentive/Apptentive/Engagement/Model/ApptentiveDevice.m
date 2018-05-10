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
static NSString *const AdvertisingIdentifierKey = @"advertisingIdentifier";

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
static NSUUID * _Nullable _currentAdvertisingIdentifier;


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

+ (void)getAdvertisingIdentifier {
	NSUUID *oldAdvertisingIdentifier = _currentAdvertisingIdentifier;
	_currentAdvertisingIdentifier = nil;
	@try {
		Class IdentifierManager = NSClassFromString(@"ASIdentifierManager");
		if (IdentifierManager) {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			id sharedManager = [IdentifierManager performSelector:NSSelectorFromString(@"sharedManager")];
			SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
			SEL advertisingTrackingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");

			if (![sharedManager respondsToSelector:advertisingIdentifierSelector] ||
				![sharedManager respondsToSelector:advertisingTrackingEnabledSelector]) {
				ApptentiveLogDebug(ApptentiveLogTagConversation, @"Unable to get advertising id: required method on ASIdentifierManager not found");
				return;
			}
			
			if (![sharedManager performSelector:advertisingTrackingEnabledSelector]) {
				ApptentiveLogDebug(ApptentiveLogTagConversation, @"Unable to get advertising id: advertising tracking disabled");
				return;
			}
			
			NSUUID *advertisingIdentifier = [sharedManager performSelector:advertisingIdentifierSelector];
			if ([advertisingIdentifier.UUIDString isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
				ApptentiveLogDebug(ApptentiveLogTagConversation, @"Unable to get advertising id: invalid value");
				return;
			}
			
			if (![advertisingIdentifier isEqual:oldAdvertisingIdentifier]) {
				ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Updated advertising id: %@", advertisingIdentifier);
			}
			_currentAdvertisingIdentifier = advertisingIdentifier;
	#pragma clang diagnostic pop
		}
	} @catch (NSException *e) {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Exception while trying to resolve advertising id.\n%@", e);
	}
}

+ (NSUUID *)advertisingIdentifier {
	return _currentAdvertisingIdentifier;
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
		_advertisingIdentifier = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:AdvertisingIdentifierKey];
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
	[aCoder encodeObject:self.advertisingIdentifier forKey:AdvertisingIdentifierKey];
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

+ (NSArray *)sensitiveKeys {
	return [super.sensitiveKeys arrayByAddingObject:@"uuid"];
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

	_advertisingIdentifier = _currentAdvertisingIdentifier;
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

- (NSString *)advertisingIdentifierString {
	return self.advertisingIdentifier.UUIDString;
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
		@"integration_config": NSStringFromSelector(@selector(integrationConfiguration)),
		@"advertiser_id": NSStringFromSelector(@selector(advertisingIdentifierString))
	};
}

@end

@implementation ApptentiveDevice (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	if ([path isEqualToString:@"uuid"]) {
		return self.UUIDString;
	} else if ([path isEqualToString:@"os_name"]) {
		return self.OSName;
	} else if ([path isEqualToString:@"os_version"]) {
		return [[ApptentiveVersion alloc] initWithString:self.OSVersionString];
	} else if ([path isEqualToString:@"os_build"]) {
		return self.OSBuild;
	} else if ([path isEqualToString:@"hardware"]) {
		return self.hardware;
	} else if ([path isEqualToString:@"carrier"]) {
		return self.carrier;
	} else if ([path isEqualToString:@"content_size_category"]) {
		return self.contentSizeCategory;
	} else if ([path isEqualToString:@"locale_raw"]) {
		return self.localeRaw;
	} else if ([path isEqualToString:@"locale_country_code"]) {
		return self.localeCountryCode;
	} else if ([path isEqualToString:@"locale_language_code"]) {
		return self.localeLanguageCode;
	} else if ([path isEqualToString:@"utc_offset"]) {
		return self.boxedUTCOffset;
	} else if ([path isEqualToString:@"integration_config"]) {
		return self.integrationConfiguration;
	} else {
		return [super valueForFieldWithPath:path];
	}
}

- (NSString *)descriptionForFieldWithPath:(NSString *)path {
	if ([path isEqualToString:@"uuid"]) {
		return @"device identifier (identifierForVendor)";
	} else if ([path isEqualToString:@"os_name"]) {
		return @"device OS name";
	} else if ([path isEqualToString:@"os_version"]) {
		return @"device OS version";
	} else if ([path isEqualToString:@"os_build"]) {
		return @"device OS build";
	} else if ([path isEqualToString:@"hardware"]) {
		return @"device hardware";
	} else if ([path isEqualToString:@"carrier"]) {
		return @"device carrier";
	} else if ([path isEqualToString:@"content_size_category"]) {
		return @"device content size category";
	} else if ([path isEqualToString:@"locale_raw"]) {
		return @"device raw locale";
	} else if ([path isEqualToString:@"locale_country_code"]) {
		return @"device locale country code";
	} else if ([path isEqualToString:@"locale_language_code"]) {
		return @"device locale language code";
	} else if ([path isEqualToString:@"utc_offset"]) {
		return @"device UTC offset";
	} else if ([path isEqualToString:@"integration_config"]) {
		return @"device integration configuration";
	} else {
		NSArray *parts = [path componentsSeparatedByString:@"/"];
		if (parts.count != 2 || ![parts[0] isEqualToString:@"custom_data"]) {
			return [NSString stringWithFormat:@"Unrecognized device field %@", path];
		}

		return [NSString stringWithFormat:@"device_data[%@]", parts[1]];
	}
}

@end

NS_ASSUME_NONNULL_END
