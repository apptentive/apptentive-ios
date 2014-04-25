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

NSString *const ATAppRatingUsesBeforePromptPreferenceKey = @"ATAppRatingUsesBeforePromptPreferenceKey";
NSString *const ATAppRatingDaysBeforePromptPreferenceKey = @"ATAppRatingDaysBeforePromptPreferenceKey";
NSString *const ATAppRatingDaysBetweenPromptsPreferenceKey = @"ATAppRatingDaysBetweenPromptsPreferenceKey";
NSString *const ATAppRatingSignificantEventsBeforePromptPreferenceKey = @"ATAppRatingSignificantEventsBeforePromptPreferenceKey";
NSString *const ATAppRatingPromptLogicPreferenceKey = @"ATAppRatingPromptLogicPreferenceKey";

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
	
	NSDictionary *innerPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"events", @"uses", nil], @"or", nil];
	NSDictionary *defaultPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", innerPromptLogic, nil], @"and", nil];
	
	NSDictionary *defaultPreferences = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 [NSNumber numberWithBool:NO], ATAppRatingClearCountsOnUpgradePreferenceKey,
		 [NSNumber numberWithUnsignedInteger:kATAppRatingDefaultUsesBeforePrompt], ATAppRatingUsesBeforePromptPreferenceKey, 
		 [NSNumber numberWithUnsignedInteger:kATAppRatingDefaultDaysBeforePrompt], ATAppRatingDaysBeforePromptPreferenceKey, 
		 [NSNumber numberWithUnsignedInteger:kATAppRatingDefaultDaysBetweenPrompts], ATAppRatingDaysBetweenPromptsPreferenceKey, 
		 [NSNumber numberWithUnsignedInteger:kATAppRatingDefaultSignificantEventsBeforePrompt], ATAppRatingSignificantEventsBeforePromptPreferenceKey,
		 [NSNumber numberWithInteger:0], ATAppRatingFlowPromptCountThisVersionKey,
		 defaultPromptLogic, ATAppRatingPromptLogicPreferenceKey, 
		 [NSNumber numberWithBool:NO], ATAppRatingSettingsAreFromServerPreferenceKey, 
		 [NSNumber numberWithBool:YES], ATAppRatingEnabledPreferenceKey,
		 nil];
	[defaults registerDefaults:defaultPreferences];
}

@end
