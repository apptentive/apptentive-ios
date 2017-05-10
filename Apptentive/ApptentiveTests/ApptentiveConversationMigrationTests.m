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

- (void)testConversationMigration {
    [ApptentiveAppDataContainer pushDataContainerWithName:@"3.5.0"];
    
    ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];
    XCTAssertNotNil(conversation);

	XCTAssertNotNil(conversation.appRelease);
	XCTAssertNotNil(conversation.SDK);
	XCTAssertNotNil(conversation.person);
	XCTAssertNotNil(conversation.device);
	XCTAssertNotNil(conversation.engagement);

	XCTAssertNotNil(conversation.appRelease.timeAtInstallTotal);
	XCTAssertNotNil(conversation.appRelease.timeAtInstallVersion);
	XCTAssertNotNil(conversation.appRelease.timeAtInstallBuild);

	XCTAssertNotNil(conversation.person.customData);

	XCTAssertNotNil(conversation.device.customData);

	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] totalCount], 1);
}

@end
