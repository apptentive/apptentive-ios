//
//  CodePointAndInteractionTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/20/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "Apptentive_Private.h"
#import "ApptentiveConversation.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"


@interface CodePointTest : CriteriaTest

@property (strong, nonatomic) ApptentiveInteractionUsageData *usageData;
@end


@implementation CodePointTest

- (void)setUp {
	[super setUp];

	self.usageData = [ApptentiveInteractionUsageData usageDataWithConversation:[[ApptentiveConversation alloc] initWithAPIKey:@"foo"]];
}

- (void)incrementCodePoint:(NSString *)codePoint {
	[self.usageData.conversation.engagement engageCodePoint:codePoint];
}

- (void)incrementInteraction:(NSString *)interactionID {
	[self.usageData.conversation.engagement engageInteraction:interactionID];
}

@end


@interface CodePointInvokesTotal : CodePointTest
@end


@implementation CodePointInvokesTotal

- (void)setUp {
	[super setUp];

	[self.usageData.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

@end


@interface CodePointInvokesVersion : CodePointTest
@end


@implementation CodePointInvokesVersion

- (void)setUp {
	[super setUp];

	[self.usageData.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (NSString *)codePointFormatString {
	return @"code_point/%@/invokes/cf_bundle_short_version_string";
}

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

@end


@interface CodePointLastInvokedAt : CodePointTest
@end

#import "Apptentive.h"


@implementation CodePointLastInvokedAt

- (void)setUp {
	[super setUp];

	[self.usageData.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.usageData.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)incrementTimeAgoCodePoint:(NSString *)codePoint {
	[self.usageData.conversation.engagement engageCodePoint:codePoint];
}

- (void)testAfter {
	[self.usageData.conversation.engagement.codePoints[@"test.code.point"] setValue:[NSDate distantPast] forKey:@"lastInvoked"];

	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	usleep(300000);
	NSLog(@"%@", [self.usageData predicateEvaluationDictionary][@"code_point/test.code.point/last_invoked_at/total"]);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testNe {
	[self.usageData.conversation.engagement engageCodePoint:@"test.code.point"];

	[self incrementCodePoint:@"switch.code.point"];
	// There is always going to be a few microseconds of time offset here, so I can't really run this test.
	//XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testEq {
	// 2 - $eq // There's no easy way to test this unless we contrive the times.
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testColon {
	// 3 - : // Ditto
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testBefore {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

@end


@interface InteractionInvokesTotal : CodePointTest
@end


@implementation InteractionInvokesTotal

- (void)setUp {
	[super setUp];

	[self.usageData.conversation.engagement warmInteraction:@"test.interaction"];
	[self.usageData.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testInteractionInvokesTotalGt {
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

- (void)testInteractionInvokesTotalLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMetForConversation:self.usageData.conversation]);
}

@end
