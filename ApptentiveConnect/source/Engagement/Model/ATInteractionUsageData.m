//
//  ATInteractionUsageData.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUsageData.h"
#import "ATEngagementBackend.h"
#import "ATAppRatingFlow_Private.h"
#import "ATUtilities.h"

@implementation ATInteractionUsageData

@synthesize timeSinceInstallTotal = _timeSinceInstallTotal;
@synthesize timeSinceInstallVersion = _timeSinceInstallVersion;
@synthesize timeSinceInstallBuild = _timeSinceInstallBuild;
@synthesize applicationVersion = _applicationVersion;
@synthesize applicationBuild = _applicationBuild;
@synthesize isUpdateVersion = _isUpdateVersion;
@synthesize isUpdateBuild = _isUpdateBuild;
@synthesize codePointInvokesTotal = _codePointInvokesTotal;
@synthesize codePointInvokesVersion = _codePointInvokesVersion;
@synthesize codePointInvokesBuild = _codePointInvokesBuild;
@synthesize codePointInvokesTimeAgo = _codePointInvokesTimeAgo;
@synthesize interactionInvokesTotal = _interactionInvokesTotal;
@synthesize interactionInvokesVersion = _interactionInvokesVersion;
@synthesize interactionInvokesBuild = _interactionInvokesBuild;
@synthesize interactionInvokesTimeAgo = _interactionInvokesTimeAgo;

- (id)initWithInteraction:(ATInteraction *)interaction {
	if (self = [super init]) {
		_interaction = interaction;
	}
	return self;
}

+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction {
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithInteraction:interaction];
	return [usageData autorelease];
}

- (NSString *)description {
	NSString *title = [NSString stringWithFormat:@"Usage Data For interaction %@", self.interaction.identifier];
	NSDictionary *data = @{@"timeSinceInstallTotal" : self.timeSinceInstallTotal ?: [NSNull null],
						   @"timeSinceInstallVersion" : self.timeSinceInstallVersion ?: [NSNull null],
						   @"timeSinceInstallBuild" : self.timeSinceInstallBuild ?: [NSNull null],
						   @"applicationVersion" : self.applicationVersion ?: [NSNull null],
						   @"applicationBuild" : self.applicationBuild ?: [NSNull null],
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

- (NSDictionary *)predicateEvaluationDictionary {
	 NSMutableDictionary *predicateEvaluationDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"time_since_install/total": self.timeSinceInstallTotal,
																										  @"time_since_install/version" : self.timeSinceInstallVersion,
																										  @"time_since_install/build" : self.timeSinceInstallBuild,
																										  @"application_version" : self.applicationVersion,
																										  @"application_build" : self.applicationBuild,
																										  @"is_update/version" : self.isUpdateVersion,
																										  @"is_update/build" : self.isUpdateBuild}];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesVersion];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesBuild];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesTimeAgo];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesVersion];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesBuild];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesTimeAgo];
	
	return predicateEvaluationDictionary;
}

- (NSNumber *)timeSinceInstallTotal {
	if (!_timeSinceInstallTotal) {
		NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
		_timeSinceInstallTotal = @(fabs([installDate timeIntervalSinceNow]));
		[_timeSinceInstallTotal retain];
	}
	
	return _timeSinceInstallTotal;
}

- (NSNumber *)timeSinceInstallVersion {
	if (!_timeSinceInstallVersion) {
		NSDate *versionInstallDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
		_timeSinceInstallVersion = @(fabs([versionInstallDate timeIntervalSinceNow]));
		[_timeSinceInstallVersion retain];
	}
	
	return _timeSinceInstallVersion;
}

- (NSNumber *)timeSinceInstallBuild {
	if (!_timeSinceInstallBuild) {
		NSDate *buildInstallDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];
		_timeSinceInstallBuild = @(fabs([buildInstallDate timeIntervalSinceNow]));
		[_timeSinceInstallBuild retain];
	}
	
	return _timeSinceInstallBuild;
}

- (NSString *)applicationVersion {
	if (!_applicationVersion) {
		_applicationVersion = [ATUtilities appVersionString] ?: @"";
		[_applicationVersion retain];
	}
	
	return _applicationVersion;
}

- (NSString *)applicationBuild {
	if (!_applicationBuild) {
		_applicationBuild = [ATUtilities buildNumberString] ?: @"";
		[_applicationBuild retain];
	}
	
	return _applicationBuild;
}

- (NSNumber *)isUpdateVersion {
	if (!_isUpdateVersion) {
		_isUpdateVersion = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementIsUpdateVersionKey];
		[_isUpdateVersion retain];
	}
	
	return _isUpdateVersion;
}

- (NSNumber *)isUpdateBuild {
	if (!_isUpdateBuild) {
		_isUpdateBuild = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementIsUpdateBuildKey];
		[_isUpdateBuild retain];
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
		_codePointInvokesTotal = [predicateSyntax retain];
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
		_codePointInvokesVersion = [predicateSyntax retain];
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
		_codePointInvokesBuild = [predicateSyntax retain];
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
		}
		_codePointInvokesTimeAgo = [predicateSyntax retain];
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
		_interactionInvokesTotal = [predicateSyntax retain];
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
		_interactionInvokesVersion = [predicateSyntax retain];
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
		_interactionInvokesBuild = [predicateSyntax retain];
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
		}
		_interactionInvokesTimeAgo = [predicateSyntax retain];
	}
	return _interactionInvokesTimeAgo;
}

@end
