//
//  ApptentiveConnectTests.m
//  ApptentiveConnectTests
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Apptentive.h"
#import "ATPersonInfo.h"
#import "ATDeviceInfo.h"
#import "ATUtilities.h"


@interface ApptentiveConnectTests : XCTestCase
@end


@implementation ApptentiveConnectTests

- (void)testCustomPersonData {
	ATPersonInfo *person = [[ATPersonInfo alloc] init];
	XCTAssertTrue([[person apiJSON] objectForKey:@"person"] != nil, @"A person should always have a base apiJSON key of 'person'");

	// Add standard types of data
	XCTAssertTrue([[[person apiJSON] objectForKey:@"person"] objectForKey:@"name"] == nil, @"Name should not be set.");
	person.name = @"Peter";
	XCTAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"name"] isEqualToString:@"Peter"], @"Name should be set to 'Peter'");
	person.name = nil;

	// Add custom person data
	[[Apptentive sharedConnection] addCustomPersonData:@"brown" withKey:@"hair_color"];
	[[Apptentive sharedConnection] addCustomPersonData:@(70) withKey:@"height"];
	[[Apptentive sharedConnection] addCustomPersonData:[NSNull null] withKey:@"nsNullCustomData"];

	// Arrays, dictionaries, etc. should throw exception if added to custom data
	NSDictionary *customDictionary = [NSDictionary dictionaryWithObject:@"thisShould" forKey:@"notWork"];
	@try {
		[[Apptentive sharedConnection] addCustomPersonData:customDictionary withKey:@"customDictionary"];
	}
	@catch (NSException *e) {
		XCTAssertTrue(e != nil, @"Attempting to add a dictionary to custom_data should throw an exception: %@", e);
	}
	@finally {
		XCTAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"customDictionary"] == nil, @"Dictionaries should not be added to custom_data");
	}

	// Test custom person data
	XCTAssertTrue(([[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] != nil), @"The person should have a `custom_data` parent attribute.");
	XCTAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"hair_color"] isEqualToString:@"brown"], @"Custom data 'hair_color' should be 'brown'");
	XCTAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"height"] isEqualToNumber:@(70)], @"Custom data 'height' should be '70'");
	XCTAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"nsNullCustomData"] isEqual:[NSNull null]], @"Custom data 'nsNullCustomData' should be equal to '[NSNull null]'");

	// Remove custom person data
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"hair_color"];
	XCTAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"hair_color"] == nil, @"The 'hair_color' custom data was removed, should no longer be in custom_data");
	XCTAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"height"] != nil, @"The 'height' custom data was not removed, should still be in custom_data");
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"height"];
	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"nsNullCustomData"];
}

- (void)testCustomDeviceData {
	ATDeviceInfo *device = [[ATDeviceInfo alloc] init];
	XCTAssertTrue([[device dictionaryRepresentation] objectForKey:@"device"] != nil, @"A device should always have a base apiJSON key of 'device'");

	// Add custom device data
	[[Apptentive sharedConnection] addCustomDeviceData:@"black" withKey:@"color"];
	[[Apptentive sharedConnection] addCustomDeviceData:@(499) withKey:@"MSRP"];
	[[Apptentive sharedConnection] addCustomDeviceData:[NSNull null] withKey:@"nsNullCustomData"];

	// Arrays, dictionaries, etc. should throw exception if added to custom data
	NSArray *customArray = [NSArray arrayWithObject:@"thisShouldNotWork"];
	@try {
		[[Apptentive sharedConnection] addCustomDeviceData:customArray withKey:@"customArray"];
	}
	@catch (NSException *e) {
		XCTAssertTrue(e != nil, @"Attempting to add an array to custom_data should throw an exception: %@", e);
	}
	@finally {
		XCTAssertTrue([[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"customArray"] == nil, @"Arrays should not be added to custom_data");
	}

	// Test custom device data
	XCTAssertTrue(([[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] != nil), @"The device should have a `custom_data` parent attribute.");
	XCTAssertTrue([[[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"color"] isEqualToString:@"black"], @"Custom data 'color' should be 'black'");
	XCTAssertTrue([[[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"MSRP"] isEqualToNumber:@(499)], @"Custom data 'MSRP' should be '499'");
	XCTAssertTrue([[[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"nsNullCustomData"] isEqual:[NSNull null]], @"Custom data 'nsNullCustomData' should be equal to '[NSNull null]'");

	// Remove custom device data
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"color"];
	XCTAssertTrue([[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"color"] == nil, @"The 'color' custom data was removed, should no longer be in custom_data");
	XCTAssertTrue([[[[device dictionaryRepresentation] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"MSRP"] != nil, @"The 'MSRP' custom data was not removed, should still be in custom_data");
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"MSRP"];
	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"nsNullCustomData"];
}

@end
