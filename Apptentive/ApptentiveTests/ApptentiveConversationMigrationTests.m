//
//  ApptentiveConversationMigrationTests.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ApptentiveConversation.h"
#import "ApptentiveAppRelease.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"
#import "ApptentiveAppDataContainer.h"

#import "ApptentiveDataManager.h"


static inline NSDate *dateFromString(NSString *date) {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"MM/dd/yyyy HH:mm:ss aa";
	return [formatter dateFromString:date];
}


@interface ApptentiveConversationMigrationTests : XCTestCase

@end


@implementation ApptentiveConversationMigrationTests

- (void)setUp {
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

// This is not working in the travis environment.
//- (void)testConversationMigration {
//	[ApptentiveAppDataContainer pushDataContainerWithName:@"3.5.0"];
//
//	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];
//	XCTAssertNotNil(conversation);
//	XCTAssertEqualObjects(conversation.legacyToken, @"1c496320bd0dbca0aad7e774f4eb3ec595f620e1df7a4afc9da37e5536bd5851");
//	XCTAssertEqualObjects(conversation.person.identifier, @"59124f8d09e3da650e000037");
//	XCTAssertEqualObjects(conversation.device.identifier, @"59124f8d09e3da650e000035");
//
//	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallTotal, dateFromString(@"04/01/2017 12:00:00 PM"));
//	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallVersion, dateFromString(@"04/02/2017 12:00:00 PM"));
//	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallBuild, dateFromString(@"04/02/2017 12:00:00 PM"));
//
//
//	XCTAssertNotNil(conversation.SDK);
//
//	XCTAssertNotNil(conversation.engagement);
//	XCTAssertEqualObjects(conversation.engagement.interactions[@"interaction_1"].lastInvoked, dateFromString(@"03/01/2017 12:00:00 PM"));
//	XCTAssertEqualObjects(conversation.engagement.interactions[@"interaction_2"].lastInvoked, dateFromString(@"03/02/2017 12:00:00 PM"));
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].buildCount, 1);
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].buildCount, 2);
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].totalCount, 3);
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].totalCount, 4);
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].versionCount, 5);
//	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].versionCount, 6);
//
//	NSDictionary *expectedPersonData = @{
//		@"string": @"String Test",
//		@"number": @22,
//		@"boolean1": @NO,
//		@"boolean2": @YES
//	};
//
//	XCTAssertEqualObjects(conversation.person.name, @"Testy McTesterson");
//	XCTAssertEqualObjects(conversation.person.emailAddress, @"test@apptentive.com");
//	XCTAssertEqualObjects(conversation.person.customData, expectedPersonData);
//
//	NSDictionary *expectedDeviceData = @{
//		@"string": @"Test String",
//		@"number": @42,
//		@"boolean1": @YES,
//		@"boolean2": @NO
//	};
//	XCTAssertEqualObjects(conversation.device.customData, expectedDeviceData);
//	XCTAssertEqualObjects(conversation.device.integrationConfiguration, @{ @"apptentive_push": @{@"token": @"abcdef123456"} });
//
//	XCTAssertEqualObjects([conversation.engagement.codePoints[@"local#app#event_1"] lastInvoked], dateFromString(@"02/01/2017 12:00:00 PM"));
//	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] buildCount], 1);
//	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] versionCount], 2);
//	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] totalCount], 3);
//}

@end
