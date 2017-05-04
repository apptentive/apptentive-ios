//
//  CriteriaTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "ApptentiveInteractionInvocation.h"
#import "Apptentive.h"
#import "ApptentiveConversation.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"


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

	self.data = [[ApptentiveConversation alloc] init];

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
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface CornerCasesThatShouldBeTrue : CriteriaTest
@end


@implementation CornerCasesThatShouldBeTrue

- (void)testCornerCasesThatShouldBeTrue {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
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

	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
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
	self.data.person.emailAddress = @"test@example.com";

	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface OperatorStartsWith : CriteriaTest
@end


@implementation OperatorStartsWith

- (void)testOperatorStartsWith {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface OperatorEndsWith : CriteriaTest
@end


@implementation OperatorEndsWith

- (void)testOperatorEndsWith {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface OperatorNot : CriteriaTest
@end


@implementation OperatorNot

- (void)testOperatorNot {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface OperatorExists : CriteriaTest
@end


@implementation OperatorExists

- (void)testOperatorExists {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end


@interface WhitespaceTrimming : CriteriaTest
@end


@implementation WhitespaceTrimming

- (void)testWhitespaceTrimming {
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.data]);
}

@end
