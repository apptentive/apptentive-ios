//
//  ApptentiveConversationMigrationTests.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ApptentiveConversation.h"

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
    NSLog(@"%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
    
    ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];
    XCTAssertNotNil(conversation);
}

@end
