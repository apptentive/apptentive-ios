//
//  ATInteractionInvocationTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/11/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ATInteractionInvocation.h"
#import "ATInteractionUsageData.h"


@interface ATInteractionInvocationTests : XCTestCase

@end


@interface ATInteractionInvocation ()
+ (NSCompoundPredicateType)compoundPredicateTypeFromString:(NSString *)predicateTypeString hasError:(nonnull BOOL *)hasError;
+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString hasError:(nonnull BOOL *)hasError;
+ (BOOL) operator:(NSPredicateOperatorType) operator isValidForParameter:(NSObject *)parameter;
+ (NSPredicate *)predicateWithLeftKeyPath:(NSString *)keyPath forObject:(NSDictionary *)context rightComplexObject:(NSDictionary *)rightComplexObject operatorType:(NSPredicateOperatorType)operatorType;
+ (NSCompoundPredicate *)compoundPredicateWithType:(NSCompoundPredicateType)type criteriaArray:(NSArray *)criteriaArray;
+ (NSCompoundPredicate *)compoundPredicateForKeyPath:(NSString *)keyPath operatorsAndValues:(NSDictionary *)operatorsAndValues;

@end


@interface ATFailingUsageData : ATInteractionUsageData
@end


@implementation ATFailingUsageData

- (NSDictionary *)predicateEvaluationDictionary {
	return nil;
}

@end


@implementation ATInteractionInvocationTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testCompoundPredicateTypeFromString {
	BOOL hasError;
	XCTAssertEqual(NSAndPredicateType, [ATInteractionInvocation compoundPredicateTypeFromString:@"$and" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSOrPredicateType, [ATInteractionInvocation compoundPredicateTypeFromString:@"$or" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSNotPredicateType, [ATInteractionInvocation compoundPredicateTypeFromString:@"$not" hasError:&hasError]);
	XCTAssertFalse(hasError);

	[ATInteractionInvocation compoundPredicateTypeFromString:@"" hasError:&hasError];
	XCTAssertTrue(hasError);
}

- (void)testPredicateOperatorTypeFromString {
	BOOL hasError;
	XCTAssertEqual(NSEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"==" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$eq" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSGreaterThanPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$gt" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSGreaterThanPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@">" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSGreaterThanOrEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$gte" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSGreaterThanOrEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@">=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSLessThanPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$lt" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSLessThanPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"<" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSLessThanOrEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$lte" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSLessThanOrEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"<=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSNotEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$ne" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSNotEqualToPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"!=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSContainsPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$contains" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSContainsPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"CONTAINS[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSBeginsWithPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$starts_with" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSBeginsWithPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"BEGINSWITH[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSEndsWithPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"$ends_with" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSEndsWithPredicateOperatorType, [ATInteractionInvocation predicateOperatorTypeFromString:@"ENDSWITH[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	[ATInteractionInvocation predicateOperatorTypeFromString:@"" hasError:&hasError];
	XCTAssertTrue(hasError);
}

- (void)testOperatorIsValidForParameterFail {
	XCTAssertFalse([ATInteractionInvocation operator:-999 isValidForParameter:@"Hey"]);
}

- (void)testPredicateWithLeftKeyPathForObjectRightComplexObjectOperatorTypeFail {
	XCTAssertNil([ATInteractionInvocation predicateWithLeftKeyPath:@"datetime" forObject:@{ @"datetime": @{@"_type": @"datetime"} } rightComplexObject:@{ @"_type": @"foo" } operatorType:NSEqualToPredicateOperatorType]);
}

- (void)testCompoundPredicateWithTypeCriteriaArray {
	XCTAssertNil([ATInteractionInvocation compoundPredicateWithType:NSAndPredicateType criteriaArray:@[@{ @"foo": [NSDate date] }]]);
}

- (void)testFailingInteractionUsageData {
	ATInteractionInvocation *invocation = [ATInteractionInvocation invocationWithJSONDictionary:@{ @"criteria": @{@"foo": @"bar"} }];

	XCTAssertFalse([invocation criteriaAreMetForUsageData:[[ATFailingUsageData alloc] init]]);
}

- (void)testFailingCompoundPredicateForKeyPath {
	ATInteractionInvocation *invocation = [ATInteractionInvocation invocationWithJSONDictionary:@{ @"criteria": @{@"$and": @{@"foo": [NSDate date]}} }];

	XCTAssertFalse([invocation criteriaAreMetForUsageData:[[ATFailingUsageData alloc] init]]);
}


@end
