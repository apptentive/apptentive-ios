//
//  CodePointAndInteractionTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/20/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "ATInteractionInvocation.h"
#import "ATInteractionUsageData.h"


@interface CodePointTest : CriteriaTest

@property (strong, nonatomic) ATInteractionUsageData *usageData;
@end


@implementation CodePointTest

- (void)setUp {
	[super setUp];

	self.usageData = [ATInteractionUsageData usageData];
}

- (void)incrementTotalCodePoint:(NSString *)codePoint {
	NSString *fullCodePoint = [NSString stringWithFormat:@"code_point/%@/invokes/total", codePoint];
	NSMutableDictionary *mutableCodePoints = [self.usageData.codePointInvokesTotal mutableCopy];
	mutableCodePoints[fullCodePoint] = @([mutableCodePoints[fullCodePoint] integerValue] + 1);
	self.usageData.codePointInvokesTotal = [NSDictionary dictionaryWithDictionary:mutableCodePoints];
}

- (void)incrementVersionCodePoint:(NSString *)codePoint {
	NSString *fullCodePoint = [NSString stringWithFormat:@"code_point/%@/invokes/version", codePoint];
	NSMutableDictionary *mutableCodePoints = [self.usageData.codePointInvokesVersion mutableCopy];
	mutableCodePoints[fullCodePoint] = @([mutableCodePoints[fullCodePoint] integerValue] + 1);
	self.usageData.codePointInvokesVersion = [NSDictionary dictionaryWithDictionary:mutableCodePoints];
}

- (void)incrementTotalInteractionCount:(NSString *)codePoint {
	NSString *fullCodePoint = [NSString stringWithFormat:@"interactions/%@/invokes/total", codePoint];
	NSMutableDictionary *mutableCodePoints = [self.usageData.interactionInvokesTotal mutableCopy];
	mutableCodePoints[fullCodePoint] = @([mutableCodePoints[fullCodePoint] integerValue] + 1);
	self.usageData.interactionInvokesTotal = [NSDictionary dictionaryWithDictionary:mutableCodePoints];
}

@end


@interface CodePointInvokesTotal : CodePointTest
@end


@implementation CodePointInvokesTotal

- (void)setUp {
	[super setUp];

	self.usageData.codePointInvokesTotal = @{ @"code_point/test.code.point/invokes/total": @0,
		@"code_point/switch.code.point/invokes/total": @0 };
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testGte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testNe {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testEq {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testColon {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testLte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testLt {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

@end


@interface CodePointInvokesVersion : CodePointTest
@end


@implementation CodePointInvokesVersion

- (void)setUp {
	[super setUp];

	self.usageData.codePointInvokesTotal = @{ @"code_point/switch.code.point/invokes/total": @0 };
	self.usageData.codePointInvokesVersion = @{ @"code_point/test.code.point/invokes/version": @0 };
}

- (NSString *)codePointFormatString {
	return @"code_point/%@/invokes/version";
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testGte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testNe {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testEq {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testColon {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testLte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testLt {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementVersionCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

@end


@interface CodePointLastInvokedAt : CodePointTest
@end

#import "ATConnect.h"


@implementation CodePointLastInvokedAt

- (void)setUp {
	[super setUp];

	self.usageData.codePointInvokesTotal = @{ @"code_point/switch.code.point/invokes/total": @0 };
	self.usageData.codePointInvokesTimeAgo = @{ @"code_point/test.code.point/last_invoked_at/total": [ATConnect timestampObjectWithDate:[NSDate date]] };
}

- (void)incrementTimeAgoCodePoint:(NSString *)codePoint {
	NSString *fullCodePoint = [NSString stringWithFormat:@"code_point/%@/last_invoked_at/total", codePoint];
	NSMutableDictionary *mutableCodePoints = [self.usageData.interactionInvokesTimeAgo mutableCopy];
	mutableCodePoints[fullCodePoint] = [ATConnect timestampObjectWithDate:[NSDate date]];
	self.usageData.interactionInvokesTimeAgo = [NSDictionary dictionaryWithDictionary:mutableCodePoints];
}

- (void)testAfter {
	self.usageData.codePointInvokesTimeAgo = @{ @"code_point/test.code.point/last_invoked_at/total": [ATConnect timestampObjectWithDate:[NSDate distantPast]] };

	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testNe {
	self.usageData.codePointInvokesTimeAgo = @{ @"code_point/test.code.point/last_invoked_at/total": [ATConnect timestampObjectWithDate:[NSDate date]] };

	[self incrementTotalCodePoint:@"switch.code.point"];
	// There is always going to be a few microseconds of time offset here, so I can't really run this test.
	//XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testEq {
	// 2 - $eq // There's no easy way to test this unless we contrive the times.
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testColon {
	// 3 - : // Ditto
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testBefore {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

@end


@interface InteractionInvokesTotal : CodePointTest
@end


@implementation InteractionInvokesTotal

- (void)setUp {
	[super setUp];

	self.usageData.codePointInvokesTotal = @{ @"code_point/switch.code.point/invokes/total": @0 };
	self.usageData.interactionInvokesTotal = @{ @"interactions/test.interaction/invokes/total": @0 };
}

- (void)testInteractionInvokesTotalGt {
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalGte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalNe {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalEq {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalColon {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalLte {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

- (void)testInteractionInvokesTotalLt {
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	[self incrementTotalCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForUsageData:self.usageData]);
}

@end
