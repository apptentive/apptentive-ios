//
//  ApptentiveInteractionInvocationTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/11/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"


@interface ApptentiveInteractionInvocationTests : XCTestCase

@end


@interface ApptentiveInteractionInvocation ()
+ (NSCompoundPredicateType)compoundPredicateTypeFromString:(NSString *)predicateTypeString hasError:(nonnull BOOL *)hasError;
+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString hasError:(nonnull BOOL *)hasError;
+ (BOOL) operator:(NSPredicateOperatorType) operator isValidForParameter:(NSObject *)parameter;
+ (NSPredicate *)predicateWithLeftKeyPath:(NSString *)keyPath forObject:(NSDictionary *)context rightComplexObject:(NSDictionary *)rightComplexObject operatorType:(NSPredicateOperatorType)operatorType;
+ (NSCompoundPredicate *)compoundPredicateWithType:(NSCompoundPredicateType)type criteriaArray:(NSArray *)criteriaArray;
+ (NSCompoundPredicate *)compoundPredicateForKeyPath:(NSString *)keyPath operatorsAndValues:(NSDictionary *)operatorsAndValues;

@end


@interface ATFailingUsageData : ApptentiveInteractionUsageData
@end


@implementation ATFailingUsageData

- (NSDictionary *)predicateEvaluationDictionary {
	return nil;
}

@end


@implementation ApptentiveInteractionInvocationTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testCompoundPredicateTypeFromString {
	BOOL hasError;
	XCTAssertEqual(NSAndPredicateType, [ApptentiveInteractionInvocation compoundPredicateTypeFromString:@"$and" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSOrPredicateType, [ApptentiveInteractionInvocation compoundPredicateTypeFromString:@"$or" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSNotPredicateType, [ApptentiveInteractionInvocation compoundPredicateTypeFromString:@"$not" hasError:&hasError]);
	XCTAssertFalse(hasError);

	[ApptentiveInteractionInvocation compoundPredicateTypeFromString:@"" hasError:&hasError];
	XCTAssertTrue(hasError);
}

- (void)testPredicateOperatorTypeFromString {
	BOOL hasError;
	XCTAssertEqual(NSEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"==" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$eq" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSGreaterThanPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$gt" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSGreaterThanPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@">" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSGreaterThanOrEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$gte" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSGreaterThanOrEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@">=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSLessThanPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$lt" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSLessThanPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"<" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSLessThanOrEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$lte" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSLessThanOrEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"<=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSNotEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$ne" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSNotEqualToPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"!=" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSContainsPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$contains" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSContainsPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"CONTAINS[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSBeginsWithPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$starts_with" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSBeginsWithPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"BEGINSWITH[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	XCTAssertEqual(NSEndsWithPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"$ends_with" hasError:&hasError]);
	XCTAssertFalse(hasError);
	XCTAssertEqual(NSEndsWithPredicateOperatorType, [ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"ENDSWITH[c]" hasError:&hasError]);
	XCTAssertFalse(hasError);

	[ApptentiveInteractionInvocation predicateOperatorTypeFromString:@"" hasError:&hasError];
	XCTAssertTrue(hasError);
}

- (void)testOperatorIsValidForParameterFail {
	XCTAssertFalse([ApptentiveInteractionInvocation operator:-999 isValidForParameter:@"Hey"]);
}

- (void)testPredicateWithLeftKeyPathForObjectRightComplexObjectOperatorTypeFail {
	XCTAssertNil([ApptentiveInteractionInvocation predicateWithLeftKeyPath:@"datetime" forObject:@{ @"datetime": @{@"_type": @"datetime"} } rightComplexObject:@{ @"_type": @"foo" } operatorType:NSEqualToPredicateOperatorType]);
}

- (void)testCompoundPredicateWithTypeCriteriaArray {
	XCTAssertNil([ApptentiveInteractionInvocation compoundPredicateWithType:NSAndPredicateType criteriaArray:@[@{ @"foo": [NSDate date] }]]);
}

@end
