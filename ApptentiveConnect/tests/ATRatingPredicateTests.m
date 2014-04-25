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
	NSString *predicateString = [ATAppRatingFlow_Private predicateStringForPromptLogic:promptObject withPredicateInfo:nil hasError:&hasError];
	XCTAssertEqualObjects(predicateString, result, @"%@ doesn't match %@", predicateString, result);
}

- (NSDictionary *)defaultPromptLogic {
	NSDictionary *innerPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"events", @"uses", nil], @"or", nil];
	NSDictionary *defaultPromptLogic = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", innerPromptLogic, nil], @"and", nil];
	return defaultPromptLogic;
}

- (NSDictionary *)allAndLogic {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"events", @"uses", nil], @"and", nil];
}

- (NSDictionary *)allOrLogic {
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"days", @"events", @"uses", nil], @"or", nil];
}

@end
