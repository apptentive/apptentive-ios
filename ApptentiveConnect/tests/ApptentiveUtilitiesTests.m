//
//  ApptentiveUtilitiesTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/15/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import "ApptentiveUtilities.h"


@interface ApptentiveUtilitiesTests : XCTestCase
@end


@implementation ApptentiveUtilitiesTests

- (void)testVersionComparisons {
	XCTAssertTrue([ApptentiveUtilities versionString:@"6.0" isEqualToVersionString:@"6.0"], @"Should be same");
	XCTAssertTrue([ApptentiveUtilities versionString:@"0.0" isEqualToVersionString:@"0.0"], @"Should be same");
	XCTAssertTrue([ApptentiveUtilities versionString:@"6.0.1" isEqualToVersionString:@"6.0.1"], @"Should be same");
	XCTAssertTrue([ApptentiveUtilities versionString:@"0.0.1" isEqualToVersionString:@"0.0.1"], @"Should be same");
	XCTAssertTrue([ApptentiveUtilities versionString:@"10.10.1" isEqualToVersionString:@"10.10.1"], @"Should be same");

	XCTAssertTrue([ApptentiveUtilities versionString:@"10.10.1" isGreaterThanVersionString:@"10.10.0"], @"Should be greater");
	XCTAssertTrue([ApptentiveUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.0.1"], @"Should be greater");
	XCTAssertTrue([ApptentiveUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.1"], @"Should be greater");

	XCTAssertTrue([ApptentiveUtilities versionString:@"5.0" isLessThanVersionString:@"5.1"], @"Should be less");
	XCTAssertTrue([ApptentiveUtilities versionString:@"5.0" isLessThanVersionString:@"6.0.1"], @"Should be less");
}

- (void)testComplexVersionComparisons {
	NSArray *versions = @[
		@[@"", @"=", @""],
		@[@" ", @"=", @" "],
		@[@"1.0.0.0", @"=", @"1"],
		@[@"1.0.0.0", @"=", @"1.0"],
		@[@"1.0.0.0", @"=", @"1.0.0"],
		@[@"1.0.0.0", @"=", @"1.0.0.0"],
		@[@"1.0.0", @"=", @"1.0.0.0"],
		@[@"1.0.", @"=", @"1.0.0.0"],
		@[@"1", @"=", @"1.0.0.0"],
		@[@"1.00", @"=", @"1.00.00.00"],
		@[@"1.01", @"=", @"1.1"],
		@[@"1.11.111.1111", @"=", @"1.11.111.1111"],
		@[@"1.2.3.4", @"=", @"1.2.3.4"],
		@[@"1.2.3.4", @"<", @"1.2.3.5"],
		@[@"1.2.3", @"<", @"1.2.4"],
		@[@"1.2", @"<", @"1.3"],
		@[@"1", @"<", @"2"],
		@[@"1.2.3.5", @">", @"1.2.3.4"],
		@[@"1.2.4", @">", @"1.2.3"],
		@[@"1.3", @">", @"1.2"],
		@[@"2", @">", @"1"],
		@[@"0", @"=", @"0"],
		@[@"0", @"=", @"0.0"],
		@[@"0", @"=", @"0.0.0"],
		@[@"0", @"=", @"0.0.0.0"],
		@[@"1", @"=", @"01.0.0.0"],
		@[@"0", @"<", @"0.0.0.1"],
		@[@"0", @"<", @"0.0.0.1"],
		@[@"0", @"<", @"1"],
		@[@"0", @"<", @"1"],
		@[@"0", @"=", @"0"],
		@[@"1", @"=", @"1"],
		@[@"1", @">", @"0"],
		@[@"0.0.0.1", @">", @"0"]
	];
	for (NSArray *versionCheck in versions) {
		NSString *left = versionCheck[0];
		NSString *compare = versionCheck[1];
		NSString *right = versionCheck[2];
		if ([compare isEqualToString:@"="]) {
			XCTAssertTrue([ApptentiveUtilities versionString:left isEqualToVersionString:right], @"%@ not equal to %@", left, right);
		} else if ([compare isEqualToString:@">"]) {
			XCTAssertTrue([ApptentiveUtilities versionString:left isGreaterThanVersionString:right], @"%@ not greater than %@", left, right);
		} else if ([compare isEqualToString:@"<"]) {
			XCTAssertTrue([ApptentiveUtilities versionString:left isLessThanVersionString:right], @"%@ not less than %@", left, right);
		}
	}
}

- (void)testEmailValidation {
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@" andrew+spam@foo.md "], @"Should be valid");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"a_blah@a.co.uk"], @"Should be valid");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"☃@☃.net"], @"Snowman! Valid!");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
	//	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@" foo@bar.com yarg@blah.com"], @"May as well accept multiple");
	//	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"Andrew Wooster <andrew@example.com>"], @"Accept contact emails");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"foo/bar=blah@example.com"], @"Accept department emails");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"!hi!%blah@example.com"], @"Should be valid");
	XCTAssertTrue([ApptentiveUtilities emailAddressIsValid:@"m@example.com"], @"Should be valid");

	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@"blah"], @"Shouldn't be valid");
	//	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@"andrew@example,com"], @"Shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@""], @"Shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@"@"], @"Shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@".com"], @"Shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@"\n"], @"Shouldn't be valid");
	//	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@"foo@yarg"], @"Shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:@""], @"empty string email shouldn't be valid");
	XCTAssertFalse([ApptentiveUtilities emailAddressIsValid:nil], @"nil email shouldn't be valid");
}

// The JSON blobs loaded here should be identical to those for the Android SDK.
- (NSDictionary *)loadJSONBlobsWithNames:(NSArray *)names {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	for (NSString *name in names) {
		NSString *fullName = [NSString stringWithFormat:@"testJsonDiffing.%@", name];
		NSURL *JSONURL = [[NSBundle bundleForClass:[self class]] URLForResource:fullName withExtension:@"json"];
		NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];
		NSError *error = nil;
		NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
		XCTAssertNotNil(dictionary, @"Error parsing JSON: %@", error);
		result[name] = dictionary;
	}

	return result;
}

- (void)testDictionaryDiff1 {
	NSDictionary *JSONBlobs = [self loadJSONBlobsWithNames:@[@"1.new", @"1.old", @"1.expected"]];

	NSDictionary *result = [ApptentiveUtilities diffDictionary:JSONBlobs[@"1.new"] againstDictionary:JSONBlobs[@"1.old"]];

	XCTAssertEqualObjects(result, JSONBlobs[@"1.expected"]);
}

- (void)testDictionaryDiff2 {
	NSDictionary *JSONBlobs = [self loadJSONBlobsWithNames:@[@"2.new", @"2.old"]];

	NSDictionary *result = [ApptentiveUtilities diffDictionary:JSONBlobs[@"2.new"] againstDictionary:JSONBlobs[@"2.old"]];

	XCTAssertEqualObjects(result, @{});
}

- (void)testDictionaryDiff4 {
	NSDictionary *oldPerson = nil;
	NSDictionary *newPerson = @{ @"custom_data": @{@"pet_name": @"Sumo"} };
	;

	NSDictionary *result = [ApptentiveUtilities diffDictionary:newPerson againstDictionary:oldPerson];

	XCTAssertEqualObjects(result, newPerson);
}

@end
