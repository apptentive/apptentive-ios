//
//  ApptentiveJSONSerializationTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 8/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJSONSerialization.h"
#import <XCTest/XCTest.h>


@interface ApptentiveJSONSerializationTests : XCTestCase

@end


@implementation ApptentiveJSONSerializationTests

- (void)setUp {
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (void)testValidSerialization {
	NSDictionary *JSONObject = @{ @"string": @"string" };

	NSData *JSONData = [ApptentiveJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:NULL];

	XCTAssertNotNil(JSONData);
}

- (void)testInvalidSerialization {
	NSDictionary *JSONObject = @{ @"date": [NSDate date] };

	NSData *JSONData = [ApptentiveJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:NULL];

	XCTAssertNil(JSONData, @"Invalid JSON object should fail to encode");

	NSError *error;
	JSONData = [ApptentiveJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:&error];

	XCTAssertNil(JSONData, @"Invalid JSON object should fail to encode");
	XCTAssertNotNil(error, @"Error should be present.");
}

- (void)testValidDeserialization {
	NSDictionary *JSONObject = @{ @"string": @"string" };

	NSData *JSONData = [ApptentiveJSONSerialization dataWithJSONObject:JSONObject options:NSJSONWritingPrettyPrinted error:NULL];

	id JSONOutputObject = [ApptentiveJSONSerialization JSONObjectWithData:JSONData error:NULL];

	XCTAssertNotNil(JSONOutputObject, "Valid JSON data should decode.");
	XCTAssertEqualObjects(JSONOutputObject, JSONObject, @"Decoded JSON should match original");
}

- (void)testInvalidDeserialization {
	NSData *JSONData = [@"This is not JSON" dataUsingEncoding:NSUTF8StringEncoding];

	id JSONOutputObject = [ApptentiveJSONSerialization JSONObjectWithData:JSONData error:NULL];

	XCTAssertNil(JSONOutputObject, "Invalid JSON data should not decode.");

	NSError *error;
	JSONOutputObject = [ApptentiveJSONSerialization JSONObjectWithData:JSONData error:&error];

	XCTAssertNil(JSONOutputObject, "Invalid JSON data should not decode.");
	XCTAssertNotNil(error, @"Error should be present.");
}

@end
