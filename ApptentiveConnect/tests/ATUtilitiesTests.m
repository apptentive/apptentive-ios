//
//  ATUtilitiesTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/15/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATUtilitiesTests.h"


@implementation ATUtilitiesTests
- (void)testEvenRect {
	CGRect testRect1 = CGRectMake(0.0, 0.0, 17.0, 21.0);
	CGRect result1 = ATCGRectOfEvenSize(testRect1);
	XCTAssertEqual(result1.size.width, (CGFloat)18.0, @"");
	XCTAssertEqual(result1.size.height, (CGFloat)22.0, @"");
	
	CGRect testRect2 = CGRectMake(0.0, 0.0, 18.0, 22.0);
	CGRect result2 = ATCGRectOfEvenSize(testRect2);
	XCTAssertEqual(result2.size.width, (CGFloat)18.0, @"");
	XCTAssertEqual(result2.size.height, (CGFloat)22.0, @"");
}

- (void)testDateFormatting {
	// This test will only pass when the time zone is PST. *sigh*
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1322609978.669914];
	XCTAssertEqualObjects(@"2011-11-29 15:39:38.669914 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.669];
	XCTAssertEqualObjects(@"2011-11-29 15:39:38.669 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	XCTAssertEqualObjects(@"2011-11-29 15:39:38 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	XCTAssertEqualObjects(@"2011-11-29 23:39:38 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]], @"date doesn't match");
	
	NSString *string = @"2012-09-07T23:01:07+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07Z";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+02:33";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2012-09-07 20:28:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111-00:33";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2012-09-07 23:34:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	// RFC3339 Format Tests.
	
	// Test example survey dates from docs.
	string = @"2013-05-12T20:04:05Z";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2013-05-12 20:04:05 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2013-06-13T20:04:09Z";
	date = [ATUtilities dateFromISO8601String:string];
	XCTAssertNotNil(date, @"date shouldn't be nil");
	XCTAssertEqualObjects(@"2013-06-13 20:04:09 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
}

- (void)testVersionComparisons {
	XCTAssertTrue([ATUtilities versionString:@"6.0" isEqualToVersionString:@"6.0"], @"Should be same");
	XCTAssertTrue([ATUtilities versionString:@"0.0" isEqualToVersionString:@"0.0"], @"Should be same");
	XCTAssertTrue([ATUtilities versionString:@"6.0.1" isEqualToVersionString:@"6.0.1"], @"Should be same");
	XCTAssertTrue([ATUtilities versionString:@"0.0.1" isEqualToVersionString:@"0.0.1"], @"Should be same");
	XCTAssertTrue([ATUtilities versionString:@"10.10.1" isEqualToVersionString:@"10.10.1"], @"Should be same");
	
	XCTAssertTrue([ATUtilities versionString:@"10.10.1" isGreaterThanVersionString:@"10.10.0"], @"Should be greater");
	XCTAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.0.1"], @"Should be greater");
	XCTAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.1"], @"Should be greater");
	
	XCTAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"5.1"], @"Should be less");
	XCTAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"6.0.1"], @"Should be less");
}

- (void)testCacheControlParsing {
	XCTAssertEqual(0., [ATUtilities maxAgeFromCacheControlHeader:nil], @"Should be same");
	XCTAssertEqual(0., [ATUtilities maxAgeFromCacheControlHeader:@""], @"Should be same");
	XCTAssertEqual(86400., [ATUtilities maxAgeFromCacheControlHeader:@"Cache-Control: max-age=86400, private"], @"Should be same");
	XCTAssertEqual(86400., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=86400, private"], @"Should be same");
	XCTAssertEqual(47.47, [ATUtilities maxAgeFromCacheControlHeader:@"max-age=47.47, private"], @"Should be same");
	XCTAssertEqual(0., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=0, private"], @"Should be same");
}

- (void)testThumbnailSize {
	CGSize imageSize, maxSize, result;
	
	imageSize = CGSizeMake(10, 10);
	maxSize = CGSizeMake(4, 3);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(3, 3)), @"Should be 3x3 thumbnail.");
	
	imageSize = CGSizeMake(10, 10);
	maxSize = CGSizeMake(11, 20);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(10, 10)), @"Should be 10x10 thumbnail.");
	
	imageSize = CGSizeMake(6, 8);
	maxSize = CGSizeMake(4, 4);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(3, 4)), @"Should be 3x4 thumbnail.");
	
	imageSize = CGSizeMake(8, 6);
	maxSize = CGSizeMake(6, 6);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(6, 4)), @"Should be 6x4 thumbnail.");
	
	imageSize = CGSizeMake(800, 600);
	maxSize = CGSizeMake(600, 600);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(600, 450)), @"Should be 600x450 thumbnail.");
	
	imageSize = CGSizeMake(0, 0);
	maxSize = CGSizeMake(6, 6);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(0, 0)), @"Should be 0x0 thumbnail.");
	
	imageSize = CGSizeMake(6, 6);
	maxSize = CGSizeMake(0, 0);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	XCTAssertTrue(CGSizeEqualToSize(result, CGSizeMake(0, 0)), @"Should be 0x0 thumbnail.");
}

- (void)testThumbnailCrop {
	CGSize imageSize, thumbSize;
	CGRect result, expected;
	
	imageSize = CGSizeMake(1200, 1600);
	thumbSize = CGSizeMake(100, 100);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(0, 200, 1200, 1200);
	XCTAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
	
	imageSize = CGSizeMake(1600, 1200);
	thumbSize = CGSizeMake(100, 100);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(200, 0, 1200, 1200);
	XCTAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
	
	imageSize = CGSizeMake(1600, 1200);
	thumbSize = CGSizeMake(800, 600);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(0, 0, 1600, 1200);
	XCTAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
}

- (void)testDictionaryEquality {
	NSDictionary *a = nil;
	NSDictionary *b = nil;
	
	XCTAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{};
	XCTAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = nil;
	b = @{};
	XCTAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{};
	b = @{};
	XCTAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{@"foo":@"bar"};
	b = @{@"foo":@"bar"};
	XCTAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @3]};
	b = @{@"foo":@[@1, @2, @4]};
	XCTAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	b = @{@"foo":@[@1, @2, @{@"narf":@"fran"}]};
	XCTAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	b = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	XCTAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
}

- (void)testArrayEquality {
	NSArray *a = nil;
	NSArray *b = nil;
	
	XCTAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[];
	XCTAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = nil;
	b = @[];
	XCTAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[];
	b = nil;
	XCTAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[];
	b = @[];
	XCTAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @3];
	b = @[@1, @2, @3];
	XCTAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @"foo"];
	b = @[@1, @2, @3];
	XCTAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @[@1, @2, @3]];
	b = @[@1, @2, @[@1, @2, @3]];
	XCTAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @[@1, @2, @{}]];
	b = @[@1, @2, @[@1, @2, @3]];
	XCTAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
}

- (void)testEmailValidation {
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@" andrew+spam@foo.md "], @"Should be valid");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"a_blah@a.co.uk"], @"Should be valid");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"☃@☃.net"], @"Snowman! Valid!");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
//	XCTAssertTrue([ATUtilities emailAddressIsValid:@" foo@bar.com yarg@blah.com"], @"May as well accept multiple");
//	XCTAssertTrue([ATUtilities emailAddressIsValid:@"Andrew Wooster <andrew@example.com>"], @"Accept contact emails");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"foo/bar=blah@example.com"], @"Accept department emails");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"!hi!%blah@example.com"], @"Should be valid");
	XCTAssertTrue([ATUtilities emailAddressIsValid:@"m@example.com"], @"Should be valid");
	
	XCTAssertFalse([ATUtilities emailAddressIsValid:@"blah"], @"Shouldn't be valid");
//	XCTAssertFalse([ATUtilities emailAddressIsValid:@"andrew@example,com"], @"Shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:@""], @"Shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:@"@"], @"Shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:@".com"], @"Shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:@"\n"], @"Shouldn't be valid");
//	XCTAssertFalse([ATUtilities emailAddressIsValid:@"foo@yarg"], @"Shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:@""], @"empty string email shouldn't be valid");
	XCTAssertFalse([ATUtilities emailAddressIsValid:nil], @"nil email shouldn't be valid");
}
@end
