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

+ (ATInteractionUsageData *)usageData {
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	return usageData;
}

- (NSString *)description {
	NSString *title = [NSString stringWithFormat:@"Engamement Framework Usage Data:"];
	
	NSDictionary *data = @{@"timeSinceInstallTotal" : self.timeSinceInstallTotal ?: [NSNull null],
						   @"timeSinceInstallVersion" : self.timeSinceInstallVersion ?: [NSNull null],
						   @"timeSinceInstallBuild" : self.timeSinceInstallBuild ?: [NSNull null],
						   @"applicationVersion" : self.applicationVersion ?: [NSNull null],
						   @"applicationBuild" : self.applicationBuild ?: [NSNull null],
						   @"sdkVersion" : self.sdkVersion ? [NSNull null],
						   @"sdkDistribution" : self.sdkDistribution ? [NSNull null],
						   @"sdkDistributionVersion" : self.sdkDistributionVersion ? [NSNull null],
						   @"isUpdateVersion" : self.isUpdateVersion ?: [NSNull null],
						   @"isUpdateBuild" : self.isUpdateBuild ?: [NSNull null],
						   @"codePointInvokesTotal" : self.codePointInvokesTotal ?: [NSNull null],
						   @"codePointInvokesVersion" : self.codePointInvokesVersion ?: [NSNull null],
						   @"codePointInvokesBuild" : self.codePointInvokesBuild ?: [NSNull null],
						   @"codePointInvokesTimeAgo" : self.codePointInvokesTimeAgo ?: [NSNull null],
						   @"interactionInvokesTotal" : self.interactionInvokesTotal ?: [NSNull null],
						   @"interactionInvokesVersion" : self.interactionInvokesVersion ?: [NSNull null],
						   @"interactionInovkesBuild" : self.interactionInvokesBuild ?: [NSNull null],
						   @"interactionInvokesTimeAgo" : self.interactionInvokesTimeAgo ?: [NSNull null]};
	NSDictionary *description = @{title : data};

	return [description description];
}

+ (void)keyPathWasSeen:(NSString *)keyPath {
	
	/*
	Record the keyPath if needed, to later be used in predicate evaluation.
	*/
	
	if ([keyPath hasPrefix:@"code_point/"]) {
		 NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		 if (components.count > 1) {
			NSString *codePoint = [components objectAtIndex:1];
			 [[ATEngagementBackend sharedBackend] codePointWasSeen:codePoint];
		 }
	} else if ([keyPath hasPrefix:@"interactions/"]) {
		NSArray *components = [keyPath componentsSeparatedByString:@"/"];
		if (components.count > 1) {
			NSString *interactionID = [components objectAtIndex:1];
			[[ATEngagementBackend sharedBackend] interactionWasSeen:interactionID];
		}
	}
}

- (NSDictionary *)predicateEvaluationDictionary {
	 NSMutableDictionary *predicateEvaluationDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"time_since_install/total": self.timeSinceInstallTotal,
																										  @"time_since_install/version" : self.timeSinceInstallVersion,
																										  @"time_since_install/build" : self.timeSinceInstallBuild,
																										  @"is_update/version" : self.isUpdateVersion,
																										  @"is_update/build" : self.isUpdateBuild}];
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
		return nil;
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
	ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
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
				NSString *criteriaKey = [NSString stringWithFormat:@"device/%@", [ATUtilities stringByEscapingForURLArguments:key]];
				predicateEvaluationDictionary[criteriaKey] = value;
			}
		}
		
		// Device custom data
		NSDictionary *customData = deviceData[@"custom_data"];
		if (customData) {
			for (NSString *key in customData) {
				NSObject *value = customData[key];
				if (value) {
					NSString *criteriaKey = [NSString stringWithFormat:@"device/custom_data/%@", [ATUtilities stringByEscapingForURLArguments:key]];
					predicateEvaluationDictionary[criteriaKey] = value;
				}
			}
		}
	}
	
	// Person
	ATPersonInfo *personInfo = [ATPersonInfo currentPerson];
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
				NSString *criteriaKey = [NSString stringWithFormat:@"person/%@", [ATUtilities stringByEscapingForURLArguments:key]];
				predicateEvaluationDictionary[criteriaKey] = value;
			}
		}
		
		// Person custom data
		NSDictionary *customData = personData[@"custom_data"];
		if (customData) {
			for (NSString *key in customData) {
				NSObject *value = customData[key];
				if (value) {
					NSString *criteriaKey = [NSString stringWithFormat:@"person/custom_data/%@", [ATUtilities stringByEscapingForURLArguments:key]];
					predicateEvaluationDictionary[criteriaKey] = value;
				}
			}
		}
	}
	
	return predicateEvaluationDictionary;
}

- (NSNumber *)timeSinceInstallTotal {
	if (!_timeSinceInstallTotal) {
		NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
		_timeSinceInstallTotal = @(fabs([installDate timeIntervalSinceNow]));
	}
	
	return _timeSinceInstallTotal;
}

- (NSNumber *)timeSinceInstallVersion {
	if (!_timeSinceInstallVersion) {
		NSDate *versionInstallDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
		_timeSinceInstallVersion = @(fabs([versionInstallDate timeIntervalSinceNow]));
	}
	
	return _timeSinceInstallVersion;
}

- (NSNumber *)timeSinceInstallBuild {
	if (!_timeSinceInstallBuild) {
		NSDate *buildInstallDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
		_timeSinceInstallBuild = @(fabs([buildInstallDate timeIntervalSinceNow]));
	}
	
	return _timeSinceInstallBuild;
}

- (NSDate *)timeAtInstallTotal {
	if (!_timeAtInstallTotal) {
		_timeAtInstallTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
	}
	return _timeAtInstallTotal;
}

- (NSDate *)timeAtInstallVersion {
	if (!_timeAtInstallVersion) {
		_timeAtInstallVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
	}
	return _timeAtInstallVersion;
}

- (NSString *)applicationVersion {
	if (!_applicationVersion) {
		_applicationVersion = [[ATUtilities appVersionString] copy];
	}
	
	return _applicationVersion;
}

- (NSString *)applicationBuild {
	if (!_applicationBuild) {
		_applicationBuild = [[ATUtilities buildNumberString] copy];
	}
	
	return _applicationBuild;
}

- (NSString *)sdkVersion {
	if (!_sdkVersion) {
		_sdkVersion = [kATConnectVersionString copy];
	}
	return _sdkVersion;
}

- (NSString *)sdkDistribution {
	if (!_sdkDistribution) {
		_sdkDistribution = [[[ATBackend sharedBackend] distributionName] copy];
	}
	return _sdkDistribution;
}

- (NSString *)sdkDistributionVersion {
	if (!_sdkDistributionVersion) {
		_sdkDistributionVersion = [[[ATBackend sharedBackend] distributionVersion] copy];
	}
	return _sdkDistributionVersion;
}

- (NSNumber *)currentTime {
	if (!_currentTime) {
		_currentTime = @([[NSDate date] timeIntervalSince1970]);
	}
	return _currentTime;
}

- (NSNumber *)isUpdateVersion {
	if (!_isUpdateVersion) {
		_isUpdateVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementIsUpdateVersionKey];
	}
	
	return _isUpdateVersion;
}

- (NSNumber *)isUpdateBuild {
	if (!_isUpdateBuild) {
		_isUpdateBuild = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementIsUpdateBuildKey];
	}
	
	return _isUpdateBuild;
}

- (NSDictionary *)codePointInvokesTotal {
	if (!_codePointInvokesTotal) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *codePointsInvokesTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesTotalKey];
		for (NSString *codePoint in codePointsInvokesTotal) {
			[predicateSyntax setObject:[codePointsInvokesTotal objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/total", codePoint]];
		}
		_codePointInvokesTotal = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	
	return _codePointInvokesTotal;
}

- (NSDictionary *)codePointInvokesVersion {
	if (!_codePointInvokesVersion) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *codePointsInvokesVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesVersionKey];
		for (NSString *codePoint in codePointsInvokesVersion) {
			[predicateSyntax setObject:[codePointsInvokesVersion objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/version", codePoint]];
		}
		_codePointInvokesVersion = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	return _codePointInvokesVersion;
}

- (NSDictionary *)codePointInvokesBuild {
	if (!_codePointInvokesBuild) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *codePointsInvokesBuild = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesBuildKey];
		for (NSString *codePoint in codePointsInvokesBuild) {
			[predicateSyntax setObject:[codePointsInvokesBuild objectForKey:codePoint] forKey:[NSString stringWithFormat:@"code_point/%@/invokes/build", codePoint]];
		}
		_codePointInvokesBuild = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	return _codePointInvokesBuild;
}

- (NSDictionary *)codePointInvokesTimeAgo {
	if (!_codePointInvokesTimeAgo) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *codePointsInvokesLastDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesLastDateKey];
		for (NSString *codePoint in codePointsInvokesLastDate) {
			NSDate *lastDate = [codePointsInvokesLastDate objectForKey:codePoint] ?: [NSDate distantPast];
			NSTimeInterval timeAgo = [[NSDate date] timeIntervalSinceDate:lastDate];
			[predicateSyntax setObject:@(timeAgo) forKey:[NSString stringWithFormat:@"code_point/%@/invokes/time_ago", codePoint]];
			
			if (codePointsInvokesLastDate[codePoint]) {
				NSString *key = [NSString stringWithFormat:@"code_point/%@/last_invoked_at/total", codePoint];
				predicateSyntax[key] = [ATConnect timestampObjectWithDate:lastDate];
			}
		}
		_codePointInvokesTimeAgo = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	return _codePointInvokesTimeAgo;
}

- (NSDictionary *)interactionInvokesTotal {
	if (!_interactionInvokesTotal) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *interactionsInvokesTotal = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesTotalKey];
		for (NSString *interactionID in interactionsInvokesTotal) {
			[predicateSyntax setObject:[interactionsInvokesTotal objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/total", interactionID]];
		}
		_interactionInvokesTotal = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	
	return _interactionInvokesTotal;
}

- (NSDictionary *)interactionInvokesVersion {
	if (!_interactionInvokesVersion) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *interactionsInvokesVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesVersionKey];
		for (NSString *interactionID in interactionsInvokesVersion) {
			[predicateSyntax setObject:[interactionsInvokesVersion objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/version", interactionID]];
		}
		_interactionInvokesVersion = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}

	return _interactionInvokesVersion;
}

- (NSDictionary *)interactionInvokesBuild {
	if (!_interactionInvokesBuild) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *interactionsInvokesBuild = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesBuildKey];
		for (NSString *interactionID in interactionsInvokesBuild) {
			[predicateSyntax setObject:[interactionsInvokesBuild objectForKey:interactionID] forKey:[NSString stringWithFormat:@"interactions/%@/invokes/build", interactionID]];
		}
		_interactionInvokesBuild = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	
	return _interactionInvokesBuild;
}

- (NSDictionary *)interactionInvokesTimeAgo {
	if (!_interactionInvokesTimeAgo) {
		NSMutableDictionary *predicateSyntax = [NSMutableDictionary dictionary];
		NSDictionary *interactionInvokesLastDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesLastDateKey];
		for (NSString *interactionID in interactionInvokesLastDate) {
			NSDate *lastDate = [interactionInvokesLastDate objectForKey:interactionID] ?: [NSDate distantPast];
			NSTimeInterval timeAgo = [[NSDate date] timeIntervalSinceDate:lastDate];
			[predicateSyntax setObject:@(timeAgo) forKey:[NSString stringWithFormat:@"interactions/%@/invokes/time_ago", interactionID]];
			
			if (interactionInvokesLastDate[interactionID]) {
				NSString *key = [NSString stringWithFormat:@"interactions/%@/last_invoked_at/total", interactionID];
				predicateSyntax[key] = [ATConnect timestampObjectWithDate:lastDate];
			}
		}
		_interactionInvokesTimeAgo = [[NSDictionary alloc] initWithDictionary:predicateSyntax];
	}
	return _interactionInvokesTimeAgo;
}

@end
