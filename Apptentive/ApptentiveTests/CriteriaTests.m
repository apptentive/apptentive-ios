//
//  CriteriaTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "Apptentive.h"
#import "ApptentiveConversation.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentivePerson.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveLog.h"
#import "ApptentiveVersion.h"


@interface CriteriaTest ()

@property (strong, nonatomic) ApptentiveConversation *data;

@end


@implementation CriteriaTest

- (NSString *)JSONFilename {
	NSString *className = NSStringFromClass([self class]);

	return [@"test" stringByAppendingString:className];
}

- (void)setUp {
	[super setUp];

	ApptentiveLogSetLevel(ApptentiveLogLevelDebug);

	NSURL *JSONURL = [[NSBundle bundleForClass:[self class]] URLForResource:self.JSONFilename withExtension:@"json"];
	NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];
	NSError *error;
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];

	if (!JSONDictionary) {
		NSLog(@"Error reading JSON: %@", error);
	} else {
		self.clause = [ApptentiveAndClause andClauseWithDictionary:JSONDictionary];
	}

	self.data = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

	[self.data.device addCustomNumber:@5 withKey:@"number_5"];
	[self.data.device addCustomString:@"qwerty" withKey:@"string_qwerty"];
	[self.data.device addCustomString:@"string with spaces" withKey:@"string with spaces"];
	[self.data.device removeCustomValueWithKey:@"key_with_null_value"];
}

@end


@interface CornerCasesThatShouldBeFalse : CriteriaTest
@end


@implementation CornerCasesThatShouldBeFalse

- (void)testCornerCasesThatShouldBeFalse {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface CornerCasesThatShouldBeTrue : CriteriaTest
@end


@implementation CornerCasesThatShouldBeTrue

- (void)testCornerCasesThatShouldBeTrue {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface DefaultValues : CriteriaTest
@end


@implementation DefaultValues

- (void)testDefaultValues {
	[self.data.engagement warmCodePoint:@"invalid_code_point"];
	[self.data.engagement warmInteraction:@"invalid_interaction"];

	[Apptentive sharedConnection].personName = nil;
	[Apptentive sharedConnection].personEmailAddress = nil;

	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface PredicateParsing : CriteriaTest
@end


@implementation PredicateParsing

- (void)testPredicateParsing {
	// On Android this just checks that the parser can parse the criteria.
	XCTAssertNotNil(self.clause);

//	There are some problems with the criteria that make it not actually work:
//	1. There is no field called, e.g. "booleanQuery". This could be custom data ("person/custom_data/booleanQuery"), but that won't work for dates or versions.
//	2. Even if we add methods to add date and version custom data (and edit the field names in the criteria), the version is set to be both equal and not equal to 1.0.0.
//	[self.data.person addCustomBool:YES withKey:@"booleanQuery"];
//	[self.data.person addCustomNumber:@(0) withKey:@"numberQuery"];
//	[self.data.person addCustomString:@"foo" withKey:@"stringQuery"];
//	[self.data.person addCustomDate:[NSDate dateWithTimeIntervalSince1970:123456789] withKey:@"dateTimeQuery"];
//	[self.data.person addCustomVersion:[[ApptentiveVersion alloc] initWithString:@"1.0.0"] withKey:@"versionQuery"];
//
//	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface OperatorContains : CriteriaTest
@end


@implementation OperatorContains

- (void)testOperatorContains {
	self.data.person.emailAddress = @"test@example.com";

	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface OperatorStartsWith : CriteriaTest
@end


@implementation OperatorStartsWith

- (void)testOperatorStartsWith {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface OperatorEndsWith : CriteriaTest
@end


@implementation OperatorEndsWith

- (void)testOperatorEndsWith {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface OperatorNot : CriteriaTest
@end


@implementation OperatorNot

- (void)testOperatorNot {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface OperatorExists : CriteriaTest
@end


@implementation OperatorExists

- (void)testOperatorExists {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end


@interface WhitespaceTrimming : CriteriaTest
@end


@implementation WhitespaceTrimming

- (void)testWhitespaceTrimming {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end

@interface OperatorStringEquals : CriteriaTest
@end

@implementation OperatorStringEquals

- (void)testWhitespaceTrimming {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end

@interface OperatorStringNotEquals : CriteriaTest
@end

@implementation OperatorStringNotEquals

- (void)testWhitespaceTrimming {
	XCTAssertTrue([self.clause criteriaMetForConversation:self.data]);
}

@end
