//
//  CodePointAndInteractionTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/20/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "Apptentive_Private.h"
#import "ApptentiveSession.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"


@interface CodePointTest : CriteriaTest

@property (strong, nonatomic) ApptentiveInteractionUsageData *usageData;
@end


@implementation CodePointTest

- (void)setUp {
	[super setUp];

	self.usageData = [ApptentiveInteractionUsageData usageDataWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];
}

- (void)incrementCodePoint:(NSString *)codePoint {
	[self.usageData.session.engagement engageCodePoint:codePoint];
}

- (void)incrementInteraction:(NSString *)interactionID {
	[self.usageData.session.engagement engageInteraction:interactionID];
}

@end


@interface CodePointInvokesTotal : CodePointTest
@end


@implementation CodePointInvokesTotal

- (void)setUp {
	[super setUp];

	[self.usageData.session.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.session.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

@end


@interface CodePointInvokesVersion : CodePointTest
@end


@implementation CodePointInvokesVersion

- (void)setUp {
	[super setUp];

	[self.usageData.session.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.session.engagement warmCodePoint:@"switch.code.point"];
}

- (NSString *)codePointFormatString {
	return @"code_point/%@/invokes/cf_bundle_short_version_string";
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

@end


@interface CodePointLastInvokedAt : CodePointTest
@end

#import "Apptentive.h"


@implementation CodePointLastInvokedAt

- (void)setUp {
	[super setUp];

	[self.usageData.session.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.session.engagement warmCodePoint:@"switch.code.point"];
}

- (void)incrementTimeAgoCodePoint:(NSString *)codePoint {
	[self.usageData.session.engagement engageCodePoint:codePoint];
}

- (void)testAfter {
	[self.usageData.session.engagement.codePoints[@"test.code.point"] setValue:[NSDate distantPast] forKey:@"lastInvoked"];

	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testNe {
	[self.usageData.session.engagement engageCodePoint:@"test.code.point"];

	[self incrementCodePoint:@"switch.code.point"];
	// There is always going to be a few microseconds of time offset here, so I can't really run this test.
	//XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testEq {
	// 2 - $eq // There's no easy way to test this unless we contrive the times.
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testColon {
	// 3 - : // Ditto
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testBefore {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

@end


@interface InteractionInvokesTotal : CodePointTest
@end


@implementation InteractionInvokesTotal

- (void)setUp {
	[super setUp];

	[self.usageData.session.engagement warmInteraction:@"test.interaction"];
	[self.usageData.session.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testInteractionInvokesTotalGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

- (void)testInteractionInvokesTotalLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConsumerData:self.usageData.session]);
}

@end
