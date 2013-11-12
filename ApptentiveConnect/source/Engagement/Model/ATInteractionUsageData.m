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

@synthesize daysSinceInstall = _daysSinceInstall;
@synthesize daysSinceUpgrade = _daysSinceUpgrade;
@synthesize applicationVersion = _applicationVersion;
@synthesize codePointInvokesTotal = _codePointInvokesTotal;
@synthesize codePointInvokesVersion = _codePointInvokesVersion;
@synthesize interactionInvokesTotal = _interactionInvokesTotal;
@synthesize interactionInvokesVersion = _interactionInvokesVersion;

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

+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction
						 daysSinceInstall:(NSNumber *)daysSinceInstall
						 daysSinceUpgrade:(NSNumber *)daysSinceUpgrade
					   applicationVersion:(NSString *)applicationVersion
					codePointInvokesTotal:(NSDictionary *)codePointInvokesTotal
				  codePointInvokesVersion:(NSDictionary *)codePointInvokesVersion
				  interactionInvokesTotal:(NSDictionary *)interactionInvokesTotal
				interactionInvokesVersion:(NSDictionary *)interactionInvokesVersion
{
	ATInteractionUsageData *usageData = [ATInteractionUsageData usageDataForInteraction:interaction];
	usageData.daysSinceInstall = daysSinceInstall;
	usageData.daysSinceUpgrade = daysSinceUpgrade;
	usageData.applicationVersion = applicationVersion;
	usageData.codePointInvokesTotal = codePointInvokesTotal;
	usageData.codePointInvokesVersion = codePointInvokesVersion;
	usageData.interactionInvokesTotal = interactionInvokesTotal;
	usageData.interactionInvokesVersion = interactionInvokesVersion;
	
	return usageData;
}

- (NSDictionary *)predicateEvaluationDictionary {
	 NSMutableDictionary *predicateEvaluationDictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"days_since_install": self.daysSinceInstall,
																										  @"days_since_upgrade" : self.daysSinceUpgrade,
																										  @"application_version" : self.applicationVersion}];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.codePointInvokesVersion];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesTotal];
	[predicateEvaluationDictionary addEntriesFromDictionary:self.interactionInvokesVersion];
	
	return predicateEvaluationDictionary;
}

- (NSNumber *)daysSinceInstall {
	if (!_daysSinceInstall) {
		NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey] ?: [NSDate date];
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		_daysSinceInstall = @([[calendar components:NSDayCalendarUnit fromDate:installDate toDate:[NSDate date] options:0] day] + 1) ?: @0;
		[_daysSinceInstall retain];
		[calendar release];
	}
	
	return _daysSinceInstall;
}

- (NSNumber *)daysSinceUpgrade {
	if (!_daysSinceUpgrade) {
		NSDate *upgradeDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey] ?: [NSDate date];		
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		_daysSinceUpgrade = @([[calendar components:NSDayCalendarUnit fromDate:upgradeDate toDate:[NSDate date] options:0] day] + 1) ?: @0;
		[_daysSinceUpgrade retain];
		[calendar release];
	}
		
	return _daysSinceUpgrade;
}

- (NSString *)applicationVersion {
	if (!_applicationVersion) {
		_applicationVersion = [ATUtilities appVersionString] ?: @"";
		[_applicationVersion retain];
	}
	
	return _applicationVersion;
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

@end
