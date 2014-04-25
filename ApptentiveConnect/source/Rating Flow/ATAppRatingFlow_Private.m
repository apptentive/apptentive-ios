//
//  ATAppRatingFlow_Private.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow_Private.h"

#define kATAppRatingDefaultUsesBeforePrompt 20
#define kATAppRatingDefaultDaysBeforePrompt 30
#define kATAppRatingDefaultDaysBetweenPrompts 5
#define kATAppRatingDefaultSignificantEventsBeforePrompt 10

NSString *const ATAppRatingClearCountsOnUpgradePreferenceKey  = @"ATAppRatingClearCountsOnUpgradePreferenceKey";
NSString *const ATAppRatingEnabledPreferenceKey = @"ATAppRatingEnabledPreferenceKey";

NSString *const ATAppRatingSettingsAreFromServerPreferenceKey = @"ATAppRatingSettingsAreFromServerPreferenceKey";

NSString *const ATAppRatingReviewURLPreferenceKey = @"ATAppRatingReviewURLPreferenceKey";

NSString *const ATAppRatingFlowLastUsedVersionKey = @"ATAppRatingFlowLastUsedVersionKey";
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey = @"ATAppRatingFlowLastUsedVersionFirstUseDateKey";
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey = @"ATAppRatingFlowDeclinedToRateThisVersionKey";
NSString *const ATAppRatingFlowUserDislikesThisVersionKey = @"ATAppRatingFlowUserDislikesThisVersionKey";
NSString *const ATAppRatingFlowPromptCountThisVersionKey = @"ATAppRatingFlowPromptCountThisVersionKey";
NSString *const ATAppRatingFlowLastPromptDateKey = @"ATAppRatingFlowLastPromptDateKey";
NSString *const ATAppRatingFlowRatedAppKey = @"ATAppRatingFlowRatedAppKey";

NSString *const ATAppRatingFlowUseCountKey = @"ATAppRatingFlowUseCountKey";
NSString *const ATAppRatingFlowSignificantEventsCountKey = @"ATAppRatingFlowSignificantEventsCountKey";

@implementation ATAppRatingFlow_Private
+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
	NSDictionary *defaultPreferences = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 [NSNumber numberWithBool:NO], ATAppRatingClearCountsOnUpgradePreferenceKey,
		 [NSNumber numberWithInteger:0], ATAppRatingFlowPromptCountThisVersionKey,
		 [NSNumber numberWithBool:NO], ATAppRatingSettingsAreFromServerPreferenceKey, 
		 [NSNumber numberWithBool:YES], ATAppRatingEnabledPreferenceKey,
		 nil];
	[defaults registerDefaults:defaultPreferences];
}

@end
