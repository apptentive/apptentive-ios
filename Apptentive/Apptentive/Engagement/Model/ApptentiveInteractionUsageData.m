//
//  ApptentiveInteractionUsageData.m
//  Apptentive
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveBackend.h"
#import "Apptentive.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"


@implementation ApptentiveInteractionUsageData

+ (ApptentiveInteractionUsageData *)usageDataWithSession:(ApptentiveSession *)session {
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:session];

	return usageData;
}

- (instancetype)initWithSession:(ApptentiveSession *)session {
	self = [super init];

	if (self) {
		_session = session;
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
			[Apptentive.shared.backend codePointWasSeen:[codePoint stringByRemovingPercentEncoding]];
		}
	} else if ([keyPath hasPrefix:@"interactions/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *interactionID = [components objectAtIndex:1];
			[Apptentive.shared.backend interactionWasSeen:interactionID];
		}
	}
}

- (NSDictionary *)versionObjectWithVersion:(ApptentiveVersion *)version {
	return @{ @"_type": @"version",
		@"version": version.versionString ?: @"0.0.0" };
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

	result[@"is_update/cf_bundle_short_version_string"] = @(self.session.appRelease.isUpdateVersion);
	result[@"is_update/cf_bundle_version"] = @(self.session.appRelease.isUpdateBuild);

	result[@"time_at_install/total"] = [Apptentive timestampObjectWithDate:self.session.appRelease.timeAtInstallTotal];
	result[@"time_at_install/cf_bundle_short_version_string"] = [Apptentive timestampObjectWithDate:self.session.appRelease.timeAtInstallVersion];
	result[@"time_at_install/cf_bundle_version"] = [Apptentive timestampObjectWithDate:self.session.appRelease.timeAtInstallBuild];

	result[@"application/cf_bundle_short_version_string"] = [self versionObjectWithVersion:self.session.appRelease.version];
	result[@"application/cf_bundle_version"] = [self versionObjectWithVersion:self.session.appRelease.build];
	result[@"application/debug"] = @(self.session.appRelease.debugBuild);

	result[@"sdk/version"] = [self versionObjectWithVersion:self.session.SDK.version];
	result[@"sdk/distribution"] = self.session.SDK.distributionName;
	result[@"sdk/distribution_version"] = [self versionObjectWithVersion:self.session.SDK.distributionVersion];

	result[@"current_time"] = [Apptentive timestampObjectWithDate:self.session.currentTime];

	for (NSString *key in self.session.engagement.codePoints) {
		[result addEntriesFromDictionary:[self countDictionaryForCount:self.session.engagement.codePoints[key] withPrefix:[@"code_point/" stringByAppendingString:[ApptentiveUtilities stringByEscapingForPredicate:key]]]];
	}

	for (NSString *key in self.session.engagement.interactions) {
		[result addEntriesFromDictionary:[self countDictionaryForCount:self.session.engagement.interactions[key] withPrefix:[@"interactions/" stringByAppendingString:[ApptentiveUtilities stringByEscapingForPredicate:key]]]];
	}

	// Device
	NSDictionary *deviceData = self.session.device.JSONDictionary;

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
	NSDictionary *personData = self.session.person.JSONDictionary;

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
