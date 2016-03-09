//
//  ATInteractionUsageData.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUsageData.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATEngagementBackend.h"
#import "ATUtilities.h"
#import "ATDeviceInfo.h"
#import "ATPersonInfo.h"

@implementation ATInteractionUsageData

@synthesize timeSinceInstallTotal = _timeSinceInstallTotal;
@synthesize timeSinceInstallBuild = _timeSinceInstallBuild;
@synthesize timeSinceInstallVersion = _timeSinceInstallVersion;

@synthesize timeAtInstallTotal = _timeAtInstallTotal;
@synthesize timeAtInstallVersion = _timeAtInstallVersion;

@synthesize applicationBuild = _applicationBuild;
@synthesize applicationVersion = _applicationVersion;

@synthesize sdkVersion = _sdkVersion;
@synthesize sdkDistribution = _sdkDistribution;
@synthesize sdkDistributionVersion = _sdkDistributionVersion;

@synthesize currentTime = _currentTime;
@synthesize isUpdateBuild = _isUpdateBuild;
@synthesize isUpdateVersion = _isUpdateVersion;

@synthesize codePointInvokesBuild = _codePointInvokesBuild;
@synthesize codePointInvokesTotal = _codePointInvokesTotal;
@synthesize codePointInvokesTimeAgo = _codePointInvokesTimeAgo;
@synthesize codePointInvokesVersion = _codePointInvokesVersion;

@synthesize interactionInvokesBuild = _interactionInvokesBuild;
@synthesize interactionInvokesTotal = _interactionInvokesTotal;
@synthesize interactionInvokesTimeAgo = _interactionInvokesTimeAgo;
@synthesize interactionInvokesVersion = _interactionInvokesVersion;

//+ (ATInteractionUsageData *)usageData {
//	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithEngagementData:[ATConnect sharedConnection].engagementBackend.engagementData];
//
//	return usageData;
//}

- (instancetype)initWithEngagementData:(NSDictionary *)engagementData {
	self = [super init];

	if (self) {
		_engagementData = engagementData;
		_currentTimeOffset = 0;
	}

	return self;
}

- (NSString *)description {
	NSString *title = [NSString stringWithFormat:@"Engamement Framework Usage Data:"];

	NSDictionary *data = @{ @"timeSinceInstallTotal": self.timeSinceInstallTotal ?: [NSNull null],
		@"timeSinceInstallVersion": self.timeSinceInstallVersion ?: [NSNull null],
		@"timeSinceInstallBuild": self.timeSinceInstallBuild ?: [NSNull null],
		@"applicationVersion": self.applicationVersion ?: [NSNull null],
		@"applicationBuild": self.applicationBuild ?: [NSNull null],
		@"sdkVersion": self.sdkVersion ?
		[NSNull null],
		@"sdkDistribution" :
		self.sdkDistribution ?
		[NSNull null],
		@"sdkDistributionVersion" :
		self.sdkDistributionVersion ?
		[NSNull null],
		@"isUpdateVersion" :
		self.isUpdateVersion ?: [NSNull null],
		@"isUpdateBuild": self.isUpdateBuild ?: [NSNull null],
		@"codePointInvokesTotal": self.codePointInvokesTotal ?: [NSNull null],
		@"codePointInvokesVersion": self.codePointInvokesVersion ?: [NSNull null],
		@"codePointInvokesBuild": self.codePointInvokesBuild ?: [NSNull null],
		@"codePointInvokesTimeAgo": self.codePointInvokesTimeAgo ?: [NSNull null],
		@"interactionInvokesTotal": self.interactionInvokesTotal ?: [NSNull null],
		@"interactionInvokesVersion": self.interactionInvokesVersion ?: [NSNull null],
		@"interactionInovkesBuild": self.interactionInvokesBuild ?: [NSNull null],
		@"interactionInvokesTimeAgo": self.interactionInvokesTimeAgo ?: [NSNull null] };
	NSDictionary *description = @{title: data};

	return [description description];
}

- (NSDictionary *)predicateEvaluationDictionary {
	NSMutableDictionary *predicateEvaluationDictionary = [NSMutableDictionary dictionaryWithDictionary:@{ @"time_since_install/total": self.timeSinceInstallTotal,
		@"time_since_install/version": self.timeSinceInstallVersion,
		@"time_since_install/build": self.timeSinceInstallBuild,
		@"is_update/version": self.isUpdateVersion,
		@"is_update/build": self.isUpdateBuild }];
	if (self.timeAtInstallTotal) {
		predicateEvaluationDictionary[@"time_at_install/total"] = [ATConnect timestampObjectWithDate:self.timeAtInstallTotal];
	}
	if (self.timeAtInstallVersion) {
		predicateEvaluationDictionary[@"time_at_install/version"] = [ATConnect timestampObjectWithDate:self.timeAtInstallVersion];
	}

	if (self.applicationVersion) {
		predicateEvaluationDictionary[@"application_version"] = self.applicationVersion;
		predicateEvaluationDictionary[@"app_release/version"] = self.applicationVersion;
		predicateEvaluationDictionary[@"application/version"] = [ATConnect versionObjectWithVersion:self.applicationVersion];
	} else {
		ATLogWarning(@"Unable to get application version. Using default value of 0.0.0");
		predicateEvaluationDictionary[@"application/version"] = [ATConnect versionObjectWithVersion:@"0.0.0"];
	}

	if (self.applicationBuild) {
		predicateEvaluationDictionary[@"application_build"] = self.applicationBuild;
		predicateEvaluationDictionary[@"app_release/build"] = self.applicationBuild;
	}

	if (self.sdkVersion) {
		predicateEvaluationDictionary[@"sdk/version"] = [ATConnect versionObjectWithVersion:self.sdkVersion];
	} else {
		ATLogError(@"Unable to find SDK version. Interaction critera don't make sense without one.");
		predicateEvaluationDictionary[@"sdk/version"] = [ATConnect versionObjectWithVersion:kATConnectVersionString];
	}

	if (self.sdkDistribution) {
		predicateEvaluationDictionary[@"sdk/distribution"] = self.sdkDistribution;
	}
	if (self.sdkDistributionVersion) {
		predicateEvaluationDictionary[@"sdk/distribution_version"] = self.sdkDistributionVersion;
	}

	predicateEvaluationDictionary[@"current_time"] = [ATConnect timestampObjectWithNumber:self.currentTime];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesVersion];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesBuild];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesTimeAgo];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesVersion];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesBuild];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesTimeAgo];

	// Device
	ATDeviceInfo *deviceInfo = [ATConnect sharedConnection].backend.currentDevice;
	if (deviceInfo) {
		NSDictionary *deviceData = deviceInfo.dictionaryRepresentation[@"device"];

		// Device information
		for (NSString *key in [deviceData allKeys]) {
			if ([key isEqualToString:@"custom_data"]) {
				// Custom data is added below.
				continue;
			}

			if ([key isEqualToString:@"integration_config"]) {
				// Skip "integration_config"; not used for targeting.
				continue;
			}

			NSObject *value = deviceData[key];
			if (value) {
				NSString *criteriaKey = [NSString stringWithFormat:@"device/%@", [ATUtilities stringByEscapingForPredicate:key]];
				predicateEvaluationDictionary[criteriaKey] = value;
			}
		}

		// Device custom data
		NSDictionary *customData = deviceData[@"custom_data"];
		if (customData) {
			for (NSString *key in customData) {
				NSObject *value = customData[key];
				if (value) {
					NSString *criteriaKey = [NSString stringWithFormat:@"device/custom_data/%@", [ATUtilities stringByEscapingForPredicate:key]];
					predicateEvaluationDictionary[criteriaKey] = value;
				}
			}
		}
	}

	// Person
	ATPersonInfo *personInfo = [ATConnect sharedConnection].backend.currentPerson;
	if (personInfo) {
		NSDictionary *personData = personInfo.dictionaryRepresentation[@"person"];

		// Person information
		for (NSString *key in [personData allKeys]) {
			if ([key isEqualToString:@"custom_data"]) {
				// Custom data is added below.
				continue;
			}

			NSObject *value = personData[key];
			if (value) {
				NSString *criteriaKey = [NSString stringWithFormat:@"person/%@", [ATUtilities stringByEscapingForPredicate:key]];
				predicateEvaluationDictionary[criteriaKey] = value;
			}
		}

		// Person custom data
		NSDictionary *customData = personData[@"custom_data"];
		if (customData) {
			for (NSString *key in customData) {
				NSObject *value = customData[key];
				if (value) {
					NSString *criteriaKey = [NSString stringWithFormat:@"person/custom_data/%@", [ATUtilities stringByEscapingForPredicate:key]];
					predicateEvaluationDictionary[criteriaKey] = value;
				}
			}
		}
	}

	return predicateEvaluationDictionary;
}

- (NSNumber *)timeSinceInstallTotal {
	NSDate *installDate = [self.engagementData objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
	return @(fabs([installDate timeIntervalSinceNow]));
}

- (NSNumber *)timeSinceInstallVersion {
	NSDate *versionInstallDate = [self.engagementData objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
	return @(fabs([versionInstallDate timeIntervalSinceNow]));
}

- (NSNumber *)timeSinceInstallBuild {
	NSDate *buildInstallDate = [self.engagementData objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
	return @(fabs([buildInstallDate timeIntervalSinceNow]));
}

- (NSDate *)timeAtInstallTotal {
	return [self.engagementData objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
}

- (NSDate *)timeAtInstallVersion {
	return [self.engagementData objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
}

- (NSString *)applicationVersion {
	return [self.engagementData objectForKey:ATEngagementApplicationVersionKey];
}

- (NSString *)applicationBuild {
	return [self.engagementData objectForKey:ATEngagementApplicationBuildKey];
}

- (NSString *)sdkVersion {
	return [self.engagementData objectForKey:ATEngagementSDKVersionKey];
}

- (NSString *)sdkDistribution {
	return [self.engagementData objectForKey:ATEngagementSDKDistributionNameKey];
}

- (NSString *)sdkDistributionVersion {
	return [self.engagementData objectForKey:ATEngagementSDKDistributionVersionKey];
}

- (NSNumber *)currentTime {
	return @([[NSDate date] timeIntervalSince1970] + self.currentTimeOffset);
}

- (NSNumber *)isUpdateVersion {
	return [self.engagementData objectForKey:ATEngagementIsUpdateVersionKey] ?: @(NO);
}

- (NSNumber *)isUpdateBuild {
	return [self.engagementData objectForKey:ATEngagementIsUpdateBuildKey] ?: @(NO);
}

- (NSDictionary *)codePointInvokesTotal {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *codePointsInvokesTotal = [self.engagementData objectForKey:ATEngagementCodePointsInvokesTotalKey];
	for (NSString *codePoint in codePointsInvokesTotal) {
		[predicateSyntax setObject:[codePointsInvokesTotal objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/total", [ATUtilities stringByEscapingForPredicate:codePoint]]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)codePointInvokesVersion {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *codePointsInvokesVersion = [self.engagementData objectForKey:ATEngagementCodePointsInvokesVersionKey];
	for (NSString *codePoint in codePointsInvokesVersion) {
		[predicateSyntax setObject:[codePointsInvokesVersion objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/version", [ATUtilities stringByEscapingForPredicate:codePoint]]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)codePointInvokesBuild {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *codePointsInvokesBuild = [self.engagementData objectForKey:ATEngagementCodePointsInvokesBuildKey];
	for (NSString *codePoint in codePointsInvokesBuild) {
		[predicateSyntax setObject:[codePointsInvokesBuild objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/build", [ATUtilities stringByEscapingForPredicate:codePoint]]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)codePointInvokesTimeAgo {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *codePointsInvokesLastDate = [self.engagementData objectForKey:ATEngagementCodePointsInvokesLastDateKey];
	for (NSString *codePoint in codePointsInvokesLastDate) {
		NSString *key = [NSString stringWithFormat:@"code_point/%@/last_invoked_at/total", [ATUtilities stringByEscapingForPredicate:codePoint]];
		NSDate *lastDate = [codePointsInvokesLastDate objectForKey:codePoint];

		predicateSyntax[key] = lastDate ? [ATConnect timestampObjectWithDate:lastDate] : [NSNull null];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)interactionInvokesTotal {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *interactionsInvokesTotal = [self.engagementData objectForKey:ATEngagementInteractionsInvokesTotalKey];
	for (NSString *interactionID in interactionsInvokesTotal) {
		[predicateSyntax setObject:[interactionsInvokesTotal objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/total", interactionID]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)interactionInvokesVersion {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *interactionsInvokesVersion = [self.engagementData objectForKey:ATEngagementInteractionsInvokesVersionKey];
	for (NSString *interactionID in interactionsInvokesVersion) {
		[predicateSyntax setObject:[interactionsInvokesVersion objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/version", interactionID]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)interactionInvokesBuild {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *interactionsInvokesBuild = [self.engagementData objectForKey:ATEngagementInteractionsInvokesBuildKey];
	for (NSString *interactionID in interactionsInvokesBuild) {
		[predicateSyntax setObject:[interactionsInvokesBuild objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/build", interactionID]];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

- (NSDictionary *)interactionInvokesTimeAgo {
	NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
	NSDictionary *interactionInvokesLastDate = [self.engagementData objectForKey:ATEngagementInteractionsInvokesLastDateKey];
	for (NSString *interactionID in interactionInvokesLastDate) {
		NSString *key = [NSString stringWithFormat:@"interactions/%@/last_invoked_at/total", interactionID];
		NSDate *lastDate = [interactionInvokesLastDate objectForKey:interactionID];

		predicateSyntax[key] = lastDate ? [ATConnect timestampObjectWithDate:lastDate] : [NSNull null];
	}
	return [[NSDictionary alloc] initWithDictionary:predicateSyntax];
}

@end
