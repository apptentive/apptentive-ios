//
//  ApptentiveInteractionUsageData.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"


@implementation ApptentiveInteractionUsageData

+ (ApptentiveInteractionUsageData *)usageDataWithConsumerData:(ApptentiveSession *)data {
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConsumerData:data];

	return usageData;
}

- (instancetype)initWithConsumerData:(ApptentiveSession *)data {
	self = [super init];

	if (self) {
		_data = data;
	}

	return self;
}

+ (void)keyPathWasSeen:(NSString *)keyPath {
	/*
	Record the keyPath if needed, to later be used in predicate evaluation.
	*/

	if ([keyPath hasPrefix:@"code_point/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *codePoint = [components objectAtIndex:1];
			[[Apptentive sharedConnection].engagementBackend codePointWasSeen:[codePoint stringByRemovingPercentEncoding]];
		}
	} else if ([keyPath hasPrefix:@"interactions/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *interactionID = [components objectAtIndex:1];
			[[Apptentive sharedConnection].engagementBackend interactionWasSeen:interactionID];
		}
	}
}

- (NSDictionary *)versionObjectWithVersion:(ApptentiveVersion *)version {
	return @{ @"_type": @"version", @"version": version.versionString ?: @"0.0.0" };
}

- (NSDictionary *)countDictionaryForCount:(ApptentiveCount *)count withPrefix:(NSString *)prefix {
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:4];

	result[[prefix stringByAppendingString:@"/invokes/total"]] = @(count.totalCount);
	result[[prefix stringByAppendingString:@"/invokes/cf_bundle_short_version_string"]] = @(count.versionCount);
	result[[prefix stringByAppendingString:@"/invokes/cf_bundle_version"]] = @(count.buildCount);
	result[[prefix stringByAppendingString:@"/last_invoked_at/total"]] = count.lastInvoked ? [Apptentive timestampObjectWithDate:count.lastInvoked] : [NSNull null];

	return result;
}

- (NSDictionary *)predicateEvaluationDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	result[@"is_update/cf_bundle_short_version_string"] = @(self.data.appRelease.isUpdateVersion);
	result[@"is_update/cf_bundle_version"] = @(self.data.appRelease.isUpdateBuild);

	result[@"time_at_install/total"] = [Apptentive timestampObjectWithDate:self.data.appRelease.timeAtInstallTotal];
	result[@"time_at_install/cf_bundle_short_version_string"] = [Apptentive timestampObjectWithDate:self.data.appRelease.timeAtInstallVersion];
	result[@"time_at_install/cf_bundle_version"] = [Apptentive timestampObjectWithDate:self.data.appRelease.timeAtInstallBuild];

	result[@"application/cf_bundle_short_version_string"] = [self versionObjectWithVersion:self.data.appRelease.version];
	result[@"application/cf_bundle_version"] = [self versionObjectWithVersion:self.data.appRelease.build];
	result[@"application/debug"] = @(self.data.appRelease.debugBuild);

	result[@"sdk/version"] = [self versionObjectWithVersion:self.data.SDK.version];
	result[@"sdk/distribution"] = self.data.SDK.distributionName;
	result[@"sdk/distribution_version"] = self.data.SDK.distributionVersion;

	result[@"current_time"] = [Apptentive timestampObjectWithDate:self.data.currentTime];

	for (NSString *key in self.data.engagement.codePoints) {
		[result addEntriesFromDictionary:[self countDictionaryForCount:self.data.engagement.codePoints[key] withPrefix:[@"code_point/" stringByAppendingString:[ApptentiveUtilities stringByEscapingForPredicate:key]]]];
	}

	for (NSString *key in self.data.engagement.interactions) {
		[result addEntriesFromDictionary:[self countDictionaryForCount:self.data.engagement.interactions[key] withPrefix:[@"interactions/" stringByAppendingString:[ApptentiveUtilities stringByEscapingForPredicate:key]]]];
	}

	// Device
	NSDictionary *deviceData = self.data.device.JSONDictionary;

	// Device information
	for (NSString *key in deviceData) {
		if ([key isEqualToString:@"custom_data"] || [key isEqualToString:@"integration_config"]) {
			continue;
		}

		NSObject *value = deviceData[key];
		if (value) {
			NSString *criteriaKey = [NSString stringWithFormat:@"device/%@", [ApptentiveUtilities stringByEscapingForPredicate:key]];

			if ([key isEqualToString:@"os_version"]) {
				value = [Apptentive versionObjectWithVersion:(NSString *)value];
			}

			result[criteriaKey] = value;
		}
	}

	// Device custom data
	NSDictionary *customDeviceData = deviceData[@"custom_data"];
	for (NSString *key in customDeviceData) {
		NSObject *value = customDeviceData[key];
		if (value) {
			NSString *criteriaKey = [NSString stringWithFormat:@"device/custom_data/%@", [ApptentiveUtilities stringByEscapingForPredicate:key]];
			result[criteriaKey] = value;
		}
	}

	// Person
	NSDictionary *personData = self.data.person.JSONDictionary;

	// Person information
	for (NSString *key in [personData allKeys]) {
		if ([key isEqualToString:@"custom_data"]) {
			// Custom data is added below.
			continue;
		}

		NSObject *value = personData[key];
		if (value) {
			NSString *criteriaKey = [NSString stringWithFormat:@"person/%@", [ApptentiveUtilities stringByEscapingForPredicate:key]];
			result[criteriaKey] = value;
		}
	}

	// Person custom data
	NSDictionary *customPersonData = personData[@"custom_data"];
	for (NSString *key in customPersonData) {
		NSObject *value = customPersonData[key];
		if (value) {
			NSString *criteriaKey = [NSString stringWithFormat:@"person/custom_data/%@", [ApptentiveUtilities stringByEscapingForPredicate:key]];
			result[criteriaKey] = value;
		}
	}

	return result;
}

@end
