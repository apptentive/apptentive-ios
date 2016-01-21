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
#import "ATConnect_Private.h"
#import "ATConnect+Debugging.h"
#import "ATEngagementBackend.h"
#import "ATUtilities.h"

@interface CodePointTest : CriteriaTest

@property (strong, nonatomic) ATEngagementBackend *engagementBackend;

@end


@implementation CodePointTest

- (void)setUp {
	[super setUp];

	[ATConnect sharedConnection].apiKey = @"123";

	self.engagementBackend = [ATConnect sharedConnection].engagementBackend;

	[self.engagementBackend resetEngagementData];
}

- (void)incrementCodePoint:(NSString *)codePoint {
	[self.engagementBackend engageCodePoint:codePoint fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:nil];
}

- (void)incrementTotalInteractionCount:(NSString *)codePoint {
	ATInteraction *interaction = [ATInteraction interactionWithJSONDictionary:@{ @"id": codePoint }];
	[self.engagementBackend interactionWasEngaged:interaction];
}

@end


@interface CodePointInvokesTotal : CodePointTest
@end


@implementation CodePointInvokesTotal

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

@end


@interface CodePointInvokesVersion : CodePointTest
@end


@implementation CodePointInvokesVersion

- (void)testGt {
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

@end


@interface CodePointLastInvokedAt : CodePointTest
@end

#import "ATConnect.h"


@implementation CodePointLastInvokedAt

- (void)testAfter {
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMet]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testNe {
	[self incrementCodePoint:@"switch.code.point"];
	// There is always going to be a few microseconds of time offset here, so I can't really run this test.
	//XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMet]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testEq {
	// 2 - $eq // There's no easy way to test this unless we contrive the times.
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testColon {
	// 3 - : // Ditto
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testBefore {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementCodePoint:@"test.code.point"];
	usleep(300000);
	XCTAssertFalse([self.interaction criteriaAreMet]);
	usleep(300000);
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

@end


@interface InteractionInvokesTotal : CodePointTest
@end


@implementation InteractionInvokesTotal

- (void)testInteractionInvokesTotalGt {
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalGte {
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalNe {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalEq {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalColon {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalLte {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

- (void)testInteractionInvokesTotalLt {
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	[self incrementCodePoint:@"switch.code.point"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertTrue([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
	[self incrementTotalInteractionCount:@"test.interaction"];
	XCTAssertFalse([self.interaction criteriaAreMet]);
}

@end
