//
//  ApptentiveConnectTests.m
//  ApptentiveConnectTests
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveConversation.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveUtilities.h"
#import <XCTest/XCTest.h>


@interface ApptentiveConnectTests : XCTestCase
@end


@implementation ApptentiveConnectTests

- (void)testCustomPersonData
{
    ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

    // Add standard types of data
    XCTAssertTrue(conversation.person.name == nil, @"Name should not be set.");

    conversation.person.name = @"Peter";

    XCTAssertTrue([conversation.person.JSONDictionary[@"name"] isEqualToString:@"Peter"], @"Name should be set to 'Peter'");

    // Add custom person data

    [conversation.person addCustomString:@"brown" withKey:@"hair_color"];
    [conversation.person addCustomNumber:@(70) withKey:@"height"];

    // Test custom person data
    XCTAssertTrue((conversation.person.JSONDictionary[@"custom_data"] != nil), @"The person should have a `custom_data` parent attribute.");
    XCTAssertTrue([conversation.person.JSONDictionary[@"custom_data"][@"hair_color"] isEqualToString:@"brown"], @"Custom data 'hair_color' should be 'brown'");
    XCTAssertTrue([conversation.person.JSONDictionary[@"custom_data"][@"height"] isEqualToNumber:@(70)], @"Custom data 'height' should be '70'");

    // Remove custom person data
    [conversation.person removeCustomValueWithKey:@"hair_color"];
    XCTAssertTrue(conversation.person.JSONDictionary[@"custom_data"][@"hair_color"] == nil, @"The 'hair_color' custom data was removed, should no longer be in custom_data");
    XCTAssertTrue(conversation.person.JSONDictionary[@"custom_data"][@"height"] != nil, @"The 'height' custom data was not removed, should still be in custom_data");
    [[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"height"];
    [[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"nsNullCustomData"];
}

- (void)testCustomDeviceData
{
    ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

    [conversation.device addCustomString:@"black" withKey:@"color"];
    [conversation.device addCustomNumber:@(499) withKey:@"MSRP"];

    // Test custom device data
    XCTAssertTrue((conversation.device.JSONDictionary[@"custom_data"] != nil), @"The device should have a `custom_data` parent attribute.");
    XCTAssertTrue([conversation.device.JSONDictionary[@"custom_data"][@"color"] isEqualToString:@"black"], @"Custom data 'color' should be 'black'");
    XCTAssertTrue([conversation.device.JSONDictionary[@"custom_data"][@"MSRP"] isEqualToNumber:@(499)], @"Custom data 'MSRP' should be '499'");

    // Remove custom device data
    [conversation.device removeCustomValueWithKey:@"color"];
    XCTAssertTrue(conversation.device.JSONDictionary[@"custom_data"][@"color"] == nil, @"The 'color' custom data was removed, should no longer be in custom_data");
    XCTAssertTrue(conversation.device.JSONDictionary[@"custom_data"][@"MSRP"] != nil, @"The 'MSRP' custom data was not removed, should still be in custom_data");
    [[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"MSRP"];
    [[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"nsNullCustomData"];
}

@end
