//
//  ATAppRatingFlow_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATAppRatingClearCountsOnUpgradePreferenceKey;
NSString *const ATAppRatingEnabledPreferenceKey;

NSString *const ATAppRatingUsesBeforePromptPreferenceKey;
NSString *const ATAppRatingDaysBeforePromptPreferenceKey;
NSString *const ATAppRatingDaysBetweenPromptsPreferenceKey;
NSString *const ATAppRatingSignificantEventsBeforePromptPreferenceKey;
NSString *const ATAppRatingPromptLogicPreferenceKey;

NSString *const ATAppRatingSettingsAreFromServerPreferenceKey;

NSString *const ATAppRatingPreferencesChangedNotification;

@interface ATAppRatingFlowPredicateInfo : NSObject
@property (nonatomic, retain) NSDate *firstUse;
@property (nonatomic, assign) NSUInteger significantEvents;
@property (nonatomic, assign) NSUInteger appUses;

@property (nonatomic, assign) NSUInteger daysBeforePrompt;
@property (nonatomic, assign) NSUInteger significantEventsBeforePrompt;
@property (nonatomic, assign) NSUInteger usesBeforePrompt;
- (double)now;
- (double)nextPromptDate;
@end

@interface ATAppRatingFlow_Private : NSObject
+ (void)registerDefaults;
+ (NSString *)predicateStringForPromptLogic:(NSObject *)promptObject hasError:(BOOL *)hasError;
+ (NSPredicate *)predicateForPromptLogic:(NSObject *)promptObject;
+ (BOOL)evaluatePredicate:(NSPredicate *)ratingsPredicate withPredicateInfo:(ATAppRatingFlowPredicateInfo *)info;
@end
