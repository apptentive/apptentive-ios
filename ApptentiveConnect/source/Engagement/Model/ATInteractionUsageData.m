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

@implementation ATInteractionUsageData

@synthesize daysSinceInstall = _daysSinceInstall;
@synthesize daysSinceUpgrade = _daysSinceUpgrade;
@synthesize applicationVersion = _applicationVersion;
@synthesize codePointInvokesTotal = _codePointInvokesTotal;
@synthesize codePointInvokesVersion = _codePointInvokesVersion;
@synthesize interactionInvokesTotal = _interactionInvokesTotal;
@synthesize interactionInvokesVersion = _interactionInvokesVersion;

- (id)initWithInteraction:(ATInteraction *)interaction atCodePoint:(NSString *)codePoint {
	if (self = [super init]) {
		_interaction = interaction;
		_codePoint = codePoint;
	}
	return self;
}

+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction atCodePoint:(NSString *)codePoint {
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] initWithInteraction:interaction atCodePoint:codePoint];
	return [usageData autorelease];
}

+ (ATInteractionUsageData *)usageDataForInteraction:(ATInteraction *)interaction
							  atCodePoint:(NSString *)codePoint
						 daysSinceInstall:(NSNumber *)daysSinceInstall
						 daysSinceUpgrade:(NSNumber *)daysSinceUpgrade
					   applicationVersion:(NSString *)applicationVersion
					codePointInvokesTotal:(NSNumber *)codePointInvokesTotal
				  codePointInvokesVersion:(NSNumber *)codePointInvokesVersion
				  interactionInvokesTotal:(NSNumber *)interactionInvokesTotal
				interactionInvokesVersion:(NSNumber *)interactionInvokesVersion
{
	ATInteractionUsageData *usageData = [ATInteractionUsageData usageDataForInteraction:interaction atCodePoint:codePoint];
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
    NSDictionary *predicateEvaluationDictionary = @{@"days_since_install": self.daysSinceInstall,
                                                    @"days_since_upgrade" : self.daysSinceUpgrade,
                                                    @"application_version" : self.applicationVersion,
                                                    [NSString stringWithFormat:@"code_point/%@/invokes/total", self.codePoint] : self.codePointInvokesTotal,
                                                    [NSString stringWithFormat:@"code_point/%@/invokes/version", self.codePoint] : self.codePointInvokesVersion,
                                                    [NSString stringWithFormat:@"interactions/%@/invokes/total", self.interaction.identifier] : self.interactionInvokesTotal,
                                                    [NSString stringWithFormat:@"interactions/%@/invokes/version", self.interaction.identifier] : self.interactionInvokesVersion};
	return predicateEvaluationDictionary;
}

- (NSNumber *)daysSinceInstall {
	if (!_daysSinceInstall) {
		NSDate *installDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInstallDateKey];
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		_daysSinceInstall = [@([[calendar components:NSDayCalendarUnit fromDate:installDate toDate:[NSDate date] options:0] day] + 1) retain];
		[calendar release];
	}
	
	return _daysSinceInstall;
}

- (NSNumber *)daysSinceUpgrade {
	if (!_daysSinceUpgrade) {
		NSDate *upgradeDate = [[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementUpgradeDateKey];
		NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		_daysSinceUpgrade = [@([[calendar components:NSDayCalendarUnit fromDate:upgradeDate toDate:[NSDate date] options:0] day] + 1) retain];
		[calendar release];
	}
		
	return _daysSinceUpgrade;
}

- (NSString *)applicationVersion {
	if (!_applicationVersion) {
		_applicationVersion = [[[NSUserDefaults standardUserDefaults] objectForKey:ATAppRatingFlowLastUsedVersionKey] retain];
	}
	
	return _applicationVersion;
}

- (NSNumber *)codePointInvokesTotal {
	if (!_codePointInvokesTotal) {
		_codePointInvokesTotal = [[[[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesTotalKey] objectForKey:self.codePoint] retain];
		if (!_codePointInvokesTotal) {
			_codePointInvokesTotal = [@0 retain];
		}
	}
	
	return _codePointInvokesTotal;
}

- (NSNumber *)codePointInvokesVersion {
	if (!_codePointInvokesVersion) {
		_codePointInvokesVersion = [[[[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementCodePointsInvokesVersionKey] objectForKey:self.codePoint] retain];
		if (!_codePointInvokesVersion) {
			_codePointInvokesVersion = [@0 retain];
		}
	}
	return _codePointInvokesVersion;
}

- (NSNumber *)interactionInvokesTotal {
	if (!_interactionInvokesTotal) {
		_interactionInvokesTotal = [[[[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesTotalKey] objectForKey:self.interaction.identifier] retain];
		if (!_interactionInvokesTotal) {
			_interactionInvokesTotal = [@0 retain];
		}
	}
	return _interactionInvokesTotal;
}

- (NSNumber *)interactionInvokesVersion {
	if (!_interactionInvokesVersion) {
		_interactionInvokesVersion = [[[[NSUserDefaults standardUserDefaults] objectForKey:ATEngagementInteractionsInvokesVersionKey] objectForKey:self.interaction.identifier] retain];
		if (!_interactionInvokesVersion) {
			_interactionInvokesVersion = [@0 retain];
		}
	}
	return _interactionInvokesVersion;
}

@end
