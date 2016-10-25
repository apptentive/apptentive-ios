//
//  CriteriaTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "ApptentiveInteractionInvocation.h"
#import "Apptentive.h"


@implementation CriteriaTest

- (NSString *)JSONFilename {
	NSString *className = NSStringFromClass([self class]);

	return [@"test" stringByAppendingString:className];
}

- (void)setUp {
	[super setUp];

	NSURL *JSONURL = [[NSBundle bundleForClass:[self class]] URLForResource:self.JSONFilename withExtension:@"json"];
	NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];
	NSError *error;
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];

	if (!JSONDictionary) {
		NSLog(@"Error reading JSON: %@", error);
	} else {
		NSDictionary *invocationDictionary = @{ @"criteria": JSONDictionary };

		self.interaction = [ApptentiveInteractionInvocation invocationWithJSONDictionary:invocationDictionary];
	}

	[[Apptentive sharedConnection] addCustomDeviceDataNumber:@5 withKey:@"number_5"];
	[[Apptentive sharedConnection] addCustomDeviceDataString:@"qwerty" withKey:@"string_qwerty"];
	[[Apptentive sharedConnection] addCustomDeviceDataString:@"string with spaces" withKey:@"string with spaces"];
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"key_with_null_value"];
}

@end


@interface CornerCasesThatShouldBeFalse : CriteriaTest
@end


@implementation CornerCasesThatShouldBeFalse

- (void)testCornerCasesThatShouldBeFalse {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface CornerCasesThatShouldBeTrue : CriteriaTest
@end


@implementation CornerCasesThatShouldBeTrue

- (void)testCornerCasesThatShouldBeTrue {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface DefaultValues : CriteriaTest
@end


@implementation DefaultValues

- (void)testDefaultValues {
	[Apptentive sharedConnection].personName = nil;
	[Apptentive sharedConnection].personEmailAddress = nil;

	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface PredicateParsing : CriteriaTest
@end


@implementation PredicateParsing

- (void)testPredicateParsing {
	XCTAssertNotNil([self.interaction valueForKey:@"criteriaPredicate"]);
}

@end


@interface OperatorContains : CriteriaTest
@end


@implementation OperatorContains

- (void)testOperatorContains {
	[Apptentive sharedConnection].personEmailAddress = @"test@example.com";
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface OperatorStartsWith : CriteriaTest
@end


@implementation OperatorStartsWith

- (void)testOperatorStartsWith {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface OperatorEndsWith : CriteriaTest
@end


@implementation OperatorEndsWith

- (void)testOperatorEndsWith {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface OperatorNot : CriteriaTest
@end


@implementation OperatorNot

- (void)testOperatorNot {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface OperatorExists : CriteriaTest
@end


@implementation OperatorExists

- (void)testOperatorExists {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface WhitespaceTrimming : CriteriaTest
@end


@implementation WhitespaceTrimming

- (void)testWhitespaceTrimming {
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end
