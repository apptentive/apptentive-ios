//
//  CriteriaTest.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTest.h"
#import "ATInteractionInvocation.h"
#import "ATConnect.h"

@implementation CriteriaTest

- (NSString *)JSONFilename {
	NSString *className = NSStringFromClass([self class]);

	return [@"test" stringByAppendingString:className];
}

- (void)setUp {
	[super setUp];

	NSURL *JSONURL= [[NSBundle bundleForClass:[self class]] URLForResource:self.JSONFilename withExtension:@"json"];
	NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];
	NSError *error;
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];

	if (!JSONDictionary) {
		NSLog(@"Error reading JSON: %@", error);
	} else {
		NSDictionary *invocationDictionary = @{ @"criteria": JSONDictionary };

		self.interaction = [ATInteractionInvocation invocationWithJSONDictionary:invocationDictionary];
	}
}

@end


@interface CornerCasesThatShouldBeFalse : CriteriaTest
@end

@implementation CornerCasesThatShouldBeFalse

- (void)testCornerCasesThatShouldBeFalse {
	XCTAssertFalse([self.interaction criteriaAreMet]);
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
	[ATConnect sharedConnection].personEmailAddress = @"test@example.com";
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end