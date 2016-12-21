//
//  ApptentiveDevice.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDevice.h"
#import "ApptentiveVersion.h"
#import "ApptentiveMutableDevice.h"

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#include <stdlib.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>

static NSString * const UUIDKey =	@"UUID";
static NSString * const OSNameKey = @"OSName";
static NSString * const OSVersionKey = @"OSVersion";
static NSString * const OSBuildKey = @"OSBuild";
static NSString * const HardwareKey = @"hardware";
static NSString * const CarrierKey = @"carrier";
static NSString * const ContentSizeCategoryKey = @"contentSizeCategory";
static NSString * const LocaleRawKey = @"localeRaw";
static NSString * const LocaleCountryCodeKey = @"localeCountryCode";
static NSString * const LocaleLanguageCodeKey = @"localeLanguageCode";
static NSString * const UTCOffsetKey = @"UTCOffset";
static NSString * const IntegrationConfigurationKey = @"integrationConfiguration";

@implementation ApptentiveDevice

- (instancetype)initWithCurrentDevice {
	self = [super init];

	if (self) {
		[self updateWithCurrentDeviceValues];
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
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
	NSDictionary *device = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"ATDeviceLastUpdateValuePreferenceKey"] objectForKey:@"device"];
	NSString *identifier;

	self = [super initWithCustomData:device[@"custom_data"] identifier:identifier];

	if (self) {
		_UUID = [[NSUUID alloc] initWithUUIDString:device[@"uuid"]];
		_OSName = device[@"os_name"];
		_OSVersion = [[ApptentiveVersion alloc] initWithString:device[@"os_version"]];
		_OSBuild = device[@"os_build"];
		_hardware = device[@"hardware"];
		_carrier = device[@"carrier"];
		_contentSizeCategory = device[@"content_size_category"];
		_localeRaw = device[@"locale_raw"];
		_localeCountryCode = device[@"locale_country_code"];
		_localeLanguageCode = device[@"locale_language_code"];
		_UTCOffset = [device[@"utc_offset"] integerValue];
		_integrationConfiguration = device[@"integration_config"];
	}

	return self;
}

- (instancetype)initWithMutableDevice:(ApptentiveMutableDevice *)mutableDevice {
	self = [self initWithCustomData:mutableDevice.customData identifier:mutableDevice.identifier];

	if (self) {
		[self updateWithCurrentDeviceValues];
	}

	return self;
}

#pragma mark - Private

- (void)updateWithCurrentDeviceValues {
	_UUID = [UIDevice currentDevice].identifierForVendor;
	_OSName = [UIDevice currentDevice].systemName;
	_OSVersion = [[ApptentiveVersion alloc] initWithString:[UIDevice currentDevice].systemVersion];

	int mib[2] = {CTL_KERN, KERN_OSVERSION};
	size_t size = 0;
	sysctl(mib, 2, NULL, &size, NULL, 0);
	char *answer = malloc(size);
	int result = sysctl(mib, 2, answer, &size, NULL, 0);
	if (result >= 0) {
		_OSBuild = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	}
	free(answer);

	struct utsname systemInfo;
	uname(&systemInfo);
	_hardware = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

	if ([CTTelephonyNetworkInfo class]) {
		CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *c = [netInfo subscriberCellularProvider];
		if (c.carrierName) {
			_carrier = c.carrierName;
		}
		netInfo = nil;
	}

	_contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;

	_localeRaw = [NSLocale currentLocale].localeIdentifier;
	NSDictionary *localeComponents = [NSLocale componentsFromLocaleIdentifier:[NSLocale currentLocale].localeIdentifier];
	_localeCountryCode = [localeComponents objectForKey:NSLocaleCountryCode];
	_localeLanguageCode = [NSLocale preferredLanguages].firstObject;
	_UTCOffset = [NSTimeZone systemTimeZone].secondsFromGMT;
#warning implement me
	_integrationConfiguration = @{};
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
