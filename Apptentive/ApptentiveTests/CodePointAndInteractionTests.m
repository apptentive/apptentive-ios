//
//  CodePointAndInteractionTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/20/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "CriteriaTests.h"
#import "Apptentive_Private.h"
#import "ApptentiveConversation.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"
#import "ApptentiveClause.h"
#import "ApptentiveConversation.h"
#import "ApptentiveCount.h"
#import "ApptentiveEngagement.h"
#import "Apptentive_Private.h"


@interface CodePointTest : CriteriaTest

@property (strong, nonatomic) ApptentiveConversation *conversation;

@end


@implementation CodePointTest

- (void)setUp {
	[super setUp];

	self.conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];
}

- (void)incrementCodePoint:(NSString *)codePoint {
	[self.conversation.engagement engageCodePoint:codePoint];
}

- (void)incrementInteraction:(NSString *)interactionID {
	[self.conversation.engagement engageInteraction:interactionID];
}

@end


@interface CodePointInvokesTotal : CodePointTest
@end


@implementation CodePointInvokesTotal

- (void)setUp {
	[super setUp];

	[self.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testGt {
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

@end


@interface CodePointInvokesVersion : CodePointTest
@end


@implementation CodePointInvokesVersion

- (void)setUp {
	[super setUp];

	[self.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (NSString *)codePointFormatString {
	return @"code_point/%@/invokes/cf_bundle_short_version_string";
}

- (void)testGt {
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

@end


@interface CodePointLastInvokedAt : CodePointTest
@end

#import "Apptentive.h"


@implementation CodePointLastInvokedAt

- (void)setUp {
	[super setUp];

	[self.conversation.engagement warmCodePoint:@"test.code.point"];
	[self.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)incrementTimeAgoCodePoint:(NSString *)codePoint {
	[self.conversation.engagement engageCodePoint:codePoint];
}

- (void)testAfter {
	[self.conversation.engagement.codePoints[@"test.code.point"] setValue:[NSDate distantPast] forKey:@"lastInvoked"];

	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testNe {
	[self.conversation.engagement engageCodePoint:@"test.code.point"];

	[self incrementCodePoint:@"switch.code.point"];
	// There is always going to be a few microseconds of time offset here, so I can't really run this test.
	//XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	usleep(300000);
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testEq {
	// 2 - $eq // There's no easy way to test this unless we contrive the times.
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testColon {
	// 3 - : // Ditto
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testBefore {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementTimeAgoCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	usleep(300000);
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

@end


@interface InteractionInvokesTotal : CodePointTest
@end


@implementation InteractionInvokesTotal

- (void)setUp {
	[super setUp];

	[self.conversation.engagement warmInteraction:@"test.interaction"];
	[self.conversation.engagement warmCodePoint:@"switch.code.point"];
}

- (void)testInteractionInvokesTotalGt {
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

- (void)testInteractionInvokesTotalLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertTrue([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
	[self incrementInteraction:@"test.interaction"];
	XCTAssertFalse([self.clause criteriaMetForConversation:self.conversation]);
}

@end
