//
//  ApptentiveConnectTests.m
//  ApptentiveConnectTests
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Apptentive.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveSession.h"
#import "ApptentivePerson.h"
#import "ApptentiveMutablePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveMutableDevice.h"


@interface ApptentiveConnectTests : XCTestCase
@end


@implementation ApptentiveConnectTests

- (void)testCustomPersonData {
	ApptentiveSession *session = [[ApptentiveSession alloc] init];

	XCTAssertTrue([session.person.JSONDictionary objectForKey:@"person"] != nil, @"A person should always have a base apiJSON key of 'person'");

	// Add standard types of data
	XCTAssertTrue(session.person.name == nil, @"Name should not be set.");

	[session updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = @"Peter";
	}];

	XCTAssertTrue([session.person.JSONDictionary[@"person"][@"name"] isEqualToString:@"Peter"], @"Name should be set to 'Peter'");

	// Add custom person data

	[session updatePerson:^(ApptentiveMutablePerson *person) {
		[person addCustomString:@"brown" withKey:@"hair_color"];
		[person addCustomNumber:@(70) withKey:@"height"];
	}];

	// Test custom person data
	XCTAssertTrue((session.person.JSONDictionary[@"person"][@"custom_data"] != nil), @"The person should have a `custom_data` parent attribute.");
	XCTAssertTrue([session.person.JSONDictionary[@"person"][@"custom_data"][@"hair_color"] isEqualToString:@"brown"], @"Custom data 'hair_color' should be 'brown'");
	XCTAssertTrue([session.person.JSONDictionary[@"person"][@"custom_data"][@"height"] isEqualToNumber:@(70)], @"Custom data 'height' should be '70'");

	// Remove custom person data
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"hair_color"];
	XCTAssertTrue(session.person.JSONDictionary[@"person"][@"custom_data"][@"hair_color"] == nil, @"The 'hair_color' custom data was removed, should no longer be in custom_data");
	XCTAssertTrue(session.person.JSONDictionary[@"person"][@"custom_data"][@"height"] != nil, @"The 'height' custom data was not removed, should still be in custom_data");
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"height"];
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"nsNullCustomData"];
}

- (void)testCustomDeviceData {
	ApptentiveSession *session = [[ApptentiveSession alloc] init];

	XCTAssertTrue([session.device.JSONDictionary objectForKey:@"device"] != nil, @"A device should always have a base apiJSON key of 'device'");

	[session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:@"black" withKey:@"color"];
		[device addCustomNumber:@(499) withKey:@"MSRP"];
	}];

	// Test custom device data
	XCTAssertTrue((session.device.JSONDictionary[@"device"][@"custom_data"] != nil), @"The device should have a `custom_data` parent attribute.");
	XCTAssertTrue([session.device.JSONDictionary[@"device"][@"custom_data"][@"color"] isEqualToString:@"black"], @"Custom data 'color' should be 'black'");
	XCTAssertTrue([session.device.JSONDictionary[@"device"][@"custom_data"][@"MSRP"] isEqualToNumber:@(499)], @"Custom data 'MSRP' should be '499'");

	// Remove custom device data
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"color"];
	XCTAssertTrue(session.device.JSONDictionary[@"device"][@"custom_data"][@"color"] == nil, @"The 'color' custom data was removed, should no longer be in custom_data");
	XCTAssertTrue(session.device.JSONDictionary[@"device"][@"custom_data"][@"MSRP"] != nil, @"The 'MSRP' custom data was not removed, should still be in custom_data");
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"MSRP"];
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"nsNullCustomData"];
}

@end
