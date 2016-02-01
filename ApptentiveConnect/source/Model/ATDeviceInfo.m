//
//  ATDeviceInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#if TARGET_OS_IPHONE
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

#import "ATDeviceInfo.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "ATDeviceUpdater.h"


@implementation ATDeviceInfo

+ (NSString *)carrier {
#if TARGET_OS_IPHONE
	NSString *result = nil;
	if ([CTTelephonyNetworkInfo class]) {
		CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
		CTCarrier *c = [netInfo subscriberCellularProvider];
		if (c.carrierName) {
			result = c.carrierName;
		}
		netInfo = nil;
	}
	return result;
#elif TARGET_OS_MAC
	return @"";
#endif
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *device = [super.dictionaryRepresentation mutableCopy];

	NSString *uuid = [ATUtilities currentDeviceID].UUIDString;
	if (uuid) {
		device[@"uuid"] = uuid;
	}

	NSString *osName = [ATUtilities currentSystemName];
	if (osName) {
		device[@"os_name"] = osName;
	}

	NSString *osVersion = [ATUtilities currentSystemVersion];
	if (osVersion) {
		device[@"os_version"] = osVersion;
	}

	NSString *systemBuild = [ATUtilities currentSystemBuild];
	if (systemBuild) {
		device[@"os_build"] = systemBuild;
	}

	NSString *machineName = [ATUtilities currentMachineName];
	if (machineName) {
		device[@"hardware"] = machineName;
	}

	NSString *carrier = [ATDeviceInfo carrier];
	if (carrier != nil) {
		device[@"carrier"] = carrier;
	}

	NSLocale *locale = [NSLocale currentLocale];
	NSString *localeIdentifier = [locale localeIdentifier];
	NSDictionary *localeComponents = [NSLocale componentsFromLocaleIdentifier:localeIdentifier];
	NSString *countryCode = [localeComponents objectForKey:NSLocaleCountryCode];
	if (localeIdentifier) {
		device[@"locale_raw"] = localeIdentifier;
	}
	if (countryCode) {
		device[@"locale_country_code"] = countryCode;
	}

	NSString *preferredLanguage = [[NSLocale preferredLanguages] firstObject];
	if (preferredLanguage) {
		device[@"locale_language_code"] = preferredLanguage;
	}

	device[@"utc_offset"] = @([[NSTimeZone systemTimeZone] secondsFromGMT]);

	NSDictionary *integrationConfiguration = [[ATConnect sharedConnection] integrationConfiguration];
	if (integrationConfiguration && [integrationConfiguration isKindOfClass:[NSDictionary class]]) {
		device[@"integration_config"] = integrationConfiguration;
	}

	return @{ @"device": device };
}

@end
