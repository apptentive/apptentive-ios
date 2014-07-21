//
//  ApptentiveMetricsTests.m
//  ApptentiveMetricsTests
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetricsTests.h"
#import "ATConnect.h"

@implementation ApptentiveMetricsTests

- (void)setUp {
	[super setUp];
	
	// Set-up code here.
}

- (void)tearDown {
	// Tear-down code here.
	
	[super tearDown];
}

- (void)testExtendedDataDate {
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
	
	NSDictionary *extendedData = [ATConnect extendedDataDate:date];
	XCTAssertNotNil(extendedData[@"time"], @"Topmost key should be time.");
	NSDictionary *data = extendedData[@"time"];
	XCTAssertTrue([data[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	XCTAssertTrue([data[@"timestamp"] isEqualToNumber:@(1000)], @"Timestamp should be 1000.");
}

- (void)testExtendedDataLocation {
	double latitude = 14;
	double longitude = 10;
	NSDictionary *extendedData = [ATConnect extendedDataLocationForLatitude:latitude longitude:longitude];
	XCTAssertNotNil(extendedData[@"location"], @"Topmost key should be location.");
	NSDictionary *data = extendedData[@"location"];
	XCTAssertTrue([data[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	NSArray *coordinates = data[@"coordinates"];
	XCTAssertTrue([coordinates[0] isEqualToNumber:@(longitude)], @"Longitude should be set in first position.");
	XCTAssertTrue([coordinates[1] isEqualToNumber:@(latitude)], @"Latitude should be set in second position.");
}

- (void)testExtendedDataCommerceItem {
	NSDictionary *commerceItem = [ATConnect extendedDataCommerceItemWithItemID:@"ID" name:@"NAME" category:@"CATEGORY" price:@(1) quantity:@(2) currency:@"CURRENCY"];
	XCTAssertTrue([commerceItem[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	XCTAssertTrue([commerceItem[@"id"] isEqualToString:@"ID"], @"ID set");
	XCTAssertTrue([commerceItem[@"name"] isEqualToString:@"NAME"], @"Name set");
	XCTAssertTrue([commerceItem[@"category"] isEqualToString:@"CATEGORY"], @"Category set");
	XCTAssertTrue([commerceItem[@"price"] isEqualToNumber:@(1)], @"Price set");
	XCTAssertTrue([commerceItem[@"quantity"] isEqualToNumber:@(2)], @"Quantity set");
	XCTAssertTrue([commerceItem[@"currency"] isEqualToString:@"CURRENCY"], @"Currency set");

	NSDictionary *nilCommerceItem = [ATConnect extendedDataCommerceItemWithItemID:nil name:nil category:nil price:nil quantity:nil currency:nil];
	XCTAssertNotNil(nilCommerceItem, @"Extended Data should still exist, even with nil keys.");
	XCTAssertTrue([nilCommerceItem[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	XCTAssertNil(nilCommerceItem[@"id"], @"Key should not exist.");
	XCTAssertNil(nilCommerceItem[@"name"], @"Key should not exist.");
	XCTAssertNil(nilCommerceItem[@"category"], @"Key should not exist.");
	XCTAssertNil(nilCommerceItem[@"price"], @"Key should not exist.");
	XCTAssertNil(nilCommerceItem[@"quantity"], @"Key should not exist.");
	XCTAssertNil(nilCommerceItem[@"currency"], @"Key should not exist.");
}

- (void)testExtendedDataCommerceTransaction {
	NSDictionary *commerceItemOne = [ATConnect extendedDataCommerceItemWithItemID:@"ID" name:@"NAME" category:@"CATEGORY" price:@(1) quantity:@(2) currency:@"CURRENCY"];
	NSDictionary *commerceItemTwo = [ATConnect extendedDataCommerceItemWithItemID:nil name:nil category:nil price:nil quantity:nil currency:nil];
	
	NSDictionary *commerceTransaction = [ATConnect extendedDataCommerceWithTransactionID:@"ID" affiliation:@"AFFILIATION" revenue:@(1) shipping:@(2) tax:@(3) currency:@"CURRENCY" commerceItems:@[commerceItemOne, commerceItemTwo]];
	NSDictionary *commerce = commerceTransaction[@"commerce"];
	
	XCTAssertTrue([commerce[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	XCTAssertTrue([commerce[@"id"] isEqualToString:@"ID"], @"ID set");
	XCTAssertTrue([commerce[@"affiliation"] isEqualToString:@"AFFILIATION"], @"Affiliation set");
	XCTAssertTrue([commerce[@"revenue"] isEqualToNumber:@(1)], @"Revenue set");
	XCTAssertTrue([commerce[@"shipping"] isEqualToNumber:@(2)], @"Shipping set");
	XCTAssertTrue([commerce[@"tax"] isEqualToNumber:@(3)], @"Tax set");
	XCTAssertTrue([commerce[@"currency"] isEqualToString:@"CURRENCY"], @"Currency set");
	XCTAssertTrue([commerce[@"items"][0] isEqualToDictionary:commerceItemOne], @"First commerce item set.");
	XCTAssertTrue([commerce[@"items"][1] isEqualToDictionary:commerceItemTwo], @"Second commerce item set.");

	NSDictionary *nilCommerceTransaction = [ATConnect extendedDataCommerceWithTransactionID:nil affiliation:nil revenue:nil shipping:nil tax:nil currency:nil commerceItems:nil];
	XCTAssertNotNil(nilCommerceTransaction, @"Extended Data should still exist, even with nil keys.");
	NSDictionary *nilCommerce = nilCommerceTransaction[@"commerce"];
	XCTAssertNotNil(nilCommerce, @"Extended Data 'commerce' key should still exist, even with nil keys.");
	XCTAssertTrue([nilCommerce[@"version"] isEqualToNumber:@(1)], @"Should have version key set to 1.");
	XCTAssertNil(nilCommerce[@"id"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"affiliation"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"revenue"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"shipping"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"tax"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"currency"], @"Key should not exist.");
	XCTAssertNil(nilCommerce[@"items"], @"Key should not exist.");
}

@end
