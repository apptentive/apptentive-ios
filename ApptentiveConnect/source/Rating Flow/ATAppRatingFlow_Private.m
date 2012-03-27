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

@implementation ATAppRatingFlowPredicateInfo
@synthesize firstUse;
@synthesize significantEvents;
@synthesize appUses;

@synthesize daysBeforePrompt;
@synthesize significantEventsBeforePrompt;
@synthesize usesBeforePrompt;

- (double)now {
	return [[NSDate date] timeIntervalSince1970];
}

- (double)nextPromptDate {
	if (!self.firstUse) {
		self.firstUse = [NSDate date];
	}
	return [self.firstUse timeIntervalSince1970] + (double)(60*60*24*self.daysBeforePrompt);
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ firstUse: %@, significantEvents: %d, appUses: %d, daysBeforePrompt: %d, significantEventsBeforePrompt: %d, usesBeforePrompt: %d", [self description], self.firstUse, self.significantEvents, self.appUses, self.daysBeforePrompt, self.significantEventsBeforePrompt, self.usesBeforePrompt];
}
@end

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
		 defaultPromptLogic, ATAppRatingPromptLogicPreferenceKey, 
		 [NSNumber numberWithBool:NO], ATAppRatingSettingsAreFromServerPreferenceKey, 
		 [NSNumber numberWithBool:YES], ATAppRatingEnabledPreferenceKey,
		 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (NSString *)predicateStringForPromptLogic:(NSObject *)promptObject hasError:(BOOL *)hasError {
	NSMutableString *result = [NSMutableString string];
	if ([promptObject isKindOfClass:[NSDictionary class]]) {
		NSDictionary *promptDictionary = (NSDictionary *)promptObject;
		for (NSString *key in promptDictionary) {
			NSString *joinWith = nil;
			if ([key isEqualToString:@"and"]) {
				joinWith = @" AND ";
			} else if ([key isEqualToString:@"or"]) {
				joinWith = @" OR ";
			} else {
				*hasError = YES;
			}
			if (!joinWith) break;
			NSMutableArray *parts = [NSMutableArray array];
			NSObject *value = [promptDictionary objectForKey:key];
			if ([value isKindOfClass:[NSString class]]) {
				NSString *partString = [ATAppRatingFlow_Private predicateStringForPromptLogic:value hasError:hasError];
				if (partString) {
					[parts addObject:partString];
				}
			} else if ([value isKindOfClass:[NSArray class]]) {
				NSArray *promptArray = (NSArray *)value;
				for (NSObject *part in promptArray) {
					NSString *partString = [ATAppRatingFlow_Private predicateStringForPromptLogic:part hasError:hasError];
					if (partString) {
						[parts addObject:partString];
					}
				}
			}
			if ([parts count]) {
				[result appendFormat:@"(%@)", [parts componentsJoinedByString:joinWith]];
			}
		}
	} else if ([promptObject isKindOfClass:[NSString class]]) {
		NSString *promptString = (NSString *)promptObject;
		if ([promptString isEqualToString:@"days"]) {
			[result appendString:@"(daysBeforePrompt == 0 || now >= nextPromptDate )"];
		} else if ([promptString isEqualToString:@"events"]) {
			[result appendString:@"(significantEventsBeforePrompt == 0 || significantEvents > significantEventsBeforePrompt)"];
		} else if ([promptString isEqualToString:@"uses"]) {
			[result appendString:@"(usesBeforePrompt == 0 || appUses > usesBeforePrompt)"];
		} else {
			*hasError = YES;
		}
	}
	return result;
}

+ (NSPredicate *)predicateForPromptLogic:(NSObject *)promptObject {
	BOOL error = NO;
	NSString *predicateString = [ATAppRatingFlow_Private predicateStringForPromptLogic:promptObject hasError:&error];
	if (!predicateString || error || [predicateString length] == 0) {
		return nil;
	}
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];
	return predicate;
}


+ (BOOL)evaluatePredicate:(NSPredicate *)ratingsPredicate withPredicateInfo:(ATAppRatingFlowPredicateInfo *)info {
	return [ratingsPredicate evaluateWithObject:info];
}
@end
