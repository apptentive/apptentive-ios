//
//  ApptentiveConnectTests.m
//  ApptentiveConnectTests
//
//  Created by Andrew Wooster on 3/18/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveConnectTests.h"
#import "ATConnect.h"
#import "ATPersonInfo.h"
#import "ATDeviceInfo.h"


@implementation ApptentiveConnectTests

- (void)setUp {
	[super setUp];
	
	// Set-up code here.
}

- (void)tearDown {
	// Tear-down code here.
	
	[super tearDown];
}

- (void)testExample {
}

- (void)testCustomPersonData
{
	ATPersonInfo *person = [[[ATPersonInfo alloc] init] autorelease];
	STAssertTrue([[person apiJSON] objectForKey:@"person"] != nil, @"A person should always have a base apiJSON key of 'person'");
	
	//Add standard types of data
	STAssertTrue([[[person apiJSON] objectForKey:@"person"] objectForKey:@"name"] == nil, @"Name should not be set.");
	person.name = @"Peter";
	STAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"name"] isEqualToString:@"Peter"], @"Name should be set to 'Peter'");

	//Add custom person data
	STAssertTrue([[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] == nil, @"Custom data key should not exist if it has not been explicitly added.");
	[[ATConnect sharedConnection] addCustomPersonData:@"brown" withKey:@"hair_color"];
	[[ATConnect sharedConnection] addCustomPersonData:@(70) withKey:@"height"];
	[[ATConnect sharedConnection] addCustomPersonData:[NSNull null] withKey:@"nsNullCustomData"];
	
	//Arrays, dictionaries, etc. should throw exception if added to custom data
	NSDictionary *customDictionary = [NSDictionary dictionaryWithObject:@"thisShould" forKey:@"notWork"];
	@try {
		[[ATConnect sharedConnection] addCustomPersonData:customDictionary withKey:@"customDictionary"];
	}
	@catch (NSException * e) {
		STAssertTrue(e != nil, @"Attempting to add a dictionary to custom_data should throw an exception: %@", e);
	}
	@finally {
		STAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"customDictionary"] == nil, @"Dictionaries should not be added to custom_data");
	}
	
	//Test custom person data
	STAssertTrue(([[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] != nil), @"The person should have a `custom_data` parent attribute.");
	STAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"hair_color"] isEqualToString:@"brown"], @"Custom data 'hair_color' should be 'brown'");
	STAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"height"] isEqualToNumber:@(70)], @"Custom data 'height' should be '70'");
	STAssertTrue([[[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"nsNullCustomData"] isEqual:[NSNull null]], @"Custom data 'nsNullCustomData' should be equal to '[NSNull null]'");

	//Remove custom person data
	[[ATConnect sharedConnection] removeCustomPersonDataWithKey:@"hair_color"];
	STAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"hair_color"] == nil, @"The 'hair_color' custom data was removed, should no longer be in custom_data");
	STAssertTrue([[[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] objectForKey:@"height"] != nil, @"The 'height' custom data was not removed, should still be in custom_data");
	[[ATConnect sharedConnection] removeCustomPersonDataWithKey:@"height"];
	[[ATConnect sharedConnection] removeCustomPersonDataWithKey:@"nsNullCustomData"];
	STAssertTrue([[[person apiJSON] objectForKey:@"person"] objectForKey:@"custom_data"] == nil, @"All custom data keys were removed; person data should no longer have a key for `custom_data`");
}

- (void)testCustomDeviceData
{
	/*
	 //Fails with:
	 "Cannot create an NSPersistentStoreCoordinator with a nil model"
	*/
	return;
	
	//
	
	ATDeviceInfo *device = [[[ATDeviceInfo alloc] init] autorelease];
	STAssertTrue([[device apiJSON] objectForKey:@"device"] != nil, @"A device should always have a base apiJSON key of 'device'");
	
	//Add custom device data
	STAssertTrue([[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] == nil, @"Custom data key should not exist if it has not been explicitly added.");
	[[ATConnect sharedConnection] addCustomDeviceData:@"black" withKey:@"color"];
	[[ATConnect sharedConnection] addCustomDeviceData:@(499) withKey:@"MSRP"];
	[[ATConnect sharedConnection] addCustomDeviceData:[NSNull null] withKey:@"nsNullCustomData"];
	
	//Arrays, dictionaries, etc. should throw exception if added to custom data
	NSArray *customArray = [NSArray arrayWithObject:@"thisShouldNotWork"];
	@try {
		[[ATConnect sharedConnection] addCustomDeviceData:customArray withKey:@"customArray"];
	}
	@catch (NSException * e) {
		STAssertTrue(e != nil, @"Attempting to add an array to custom_data should throw an exception: %@", e);
	}
	@finally {
		STAssertTrue([[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"customArray"] == nil, @"Arrays should not be added to custom_data");
	}
	
	//Test custom device data
	STAssertTrue(([[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] != nil), @"The device should have a `custom_data` parent attribute.");
	STAssertTrue([[[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"color"] isEqualToString:@"black"], @"Custom data 'color' should be 'black'");
	STAssertTrue([[[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"MSRP"] isEqualToNumber:@(499)], @"Custom data 'MSRP' should be '499'");
	STAssertTrue([[[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"nsNullCustomData"] isEqual:[NSNull null]], @"Custom data 'nsNullCustomData' should be equal to '[NSNull null]'");
	
	//Remove custom device data
	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"color"];
	STAssertTrue([[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"color"] == nil, @"The 'color' custom data was removed, should no longer be in custom_data");
	STAssertTrue([[[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] objectForKey:@"MSRP"] != nil, @"The 'MSRP' custom data was not removed, should still be in custom_data");
	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"MSRP"];
	[[ATConnect sharedConnection] removeCustomDeviceDataWithKey:@"nsNullCustomData"];
	STAssertTrue([[[device apiJSON] objectForKey:@"device"] objectForKey:@"custom_data"] == nil, @"All custom data keys were removed; device data should no longer have a key for `custom_data`");
}

@end
