//
//  ATAppRatingFlow_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString *const ATAppRatingClearCountsOnUpgradePreferenceKey;
NSString *const ATAppRatingEnabledPreferenceKey;

NSString *const ATAppRatingSettingsAreFromServerPreferenceKey;

NSString *const ATAppRatingReviewURLPreferenceKey;



NSString *const ATAppRatingFlowLastUsedVersionKey;
NSString *const ATAppRatingFlowLastUsedVersionFirstUseDateKey;
NSString *const ATAppRatingFlowDeclinedToRateThisVersionKey;
NSString *const ATAppRatingFlowUserDislikesThisVersionKey;
NSString *const ATAppRatingFlowPromptCountThisVersionKey;
NSString *const ATAppRatingFlowLastPromptDateKey;
NSString *const ATAppRatingFlowRatedAppKey;

NSString *const ATAppRatingFlowUseCountKey;
NSString *const ATAppRatingFlowSignificantEventsCountKey;

@interface ATAppRatingFlow_Private : NSObject
+ (void)registerDefaults;

@end

