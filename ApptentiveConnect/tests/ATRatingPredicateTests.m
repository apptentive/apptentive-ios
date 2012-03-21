//
//  ATRatingPredicateTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATRatingPredicateTests.h"

@implementation ATRatingPredicateTests
- (void)predicateForObject:(NSObject *)promptObject shouldEqualString:(NSString *)result {
	BOOL hasError = NO;
	NSString *predicateString = [ATAppRatingFlow_Private predicateStringForPromptLogic:promptObject hasError:&hasError];
	STAssertEqualObjects(predicateString, result, [NSString stringWithFormat:@"%@ doesn't match %@", predicateString, result]);
}

- (NSDictionary *)defaultPromptLogic {
	NSDictionary *innerPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"events", @"uses", nil], @"or", nil];
	NSDictionary *defaultPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", innerPromptLogic, nil], @"and", nil];
	return defaultPromptLogic;
}

- (NSDictionary *)allAndLogic {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"events", @"uses", nil], @"and", nil];
}

- (void)testPredicateStrings {
	[self predicateForObject:[self defaultPromptLogic] shouldEqualString:@"((daysBeforePrompt == 0 || now >= nextPromptDate ) AND ((significantEventsBeforePrompt == 0 || significantEvents > significantEventsBeforePrompt) OR (usesBeforePrompt == 0 || appUses > usesBeforePrompt)))"];
}

- (void)testDefaultPredicate1 {
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 0;
	info.significantEventsBeforePrompt = 5;
	info.significantEvents = 4;
	info.usesBeforePrompt = 20;
	info.appUses = 3;
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self defaultPromptLogic]];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	info.significantEvents = 6;
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	info.appUses = 21;
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	info.significantEvents = 4;
	
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	[info release], info = nil;
}

- (void)testAllAndPredicate {
	ATAppRatingFlowPredicateInfo *info = [[ATAppRatingFlowPredicateInfo alloc] init];
	info.daysBeforePrompt = 30;
	info.significantEventsBeforePrompt = 10;
	info.significantEvents = 4;
	info.usesBeforePrompt = 5;
	info.appUses = 3;
	NSPredicate *predicate = [ATAppRatingFlow_Private predicateForPromptLogic:[self allAndLogic]];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	
	info.firstUse = [NSDate dateWithTimeInterval:-1.0*(31*60*60*24) sinceDate:[NSDate date]];
	info.significantEvents = 11;
	info.appUses = 6;
	
	STAssertTrue([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should be true.");
	
	
	info.firstUse = [NSDate dateWithTimeInterval:-1.0*(10*60*60*24) sinceDate:[NSDate date]];
	STAssertFalse([ATAppRatingFlow_Private evaluatePredicate:predicate withPredicateInfo:info], @"Predicate should not be true.");
	[info release], info = nil;
}
@end
