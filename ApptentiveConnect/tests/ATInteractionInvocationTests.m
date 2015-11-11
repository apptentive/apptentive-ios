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

@interface ATInteractionInvocationTests : XCTestCase

@end

@interface ATInteractionInvocation ()
+ (NSCompoundPredicateType)compoundPredicateTypeFromString:(NSString *)predicateTypeString hasError:(nonnull BOOL *)hasError;
+ (NSPredicateOperatorType)predicateOperatorTypeFromString:(NSString *)operatorString hasError:(nonnull BOOL *)hasError;
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

@end
