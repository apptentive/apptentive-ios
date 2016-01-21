//
//  ATAPIself.requestTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ATAPIRequest.h"
#import "ATURLConnection.h"

@interface ATAPIRequest ()

- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender;

@end

@interface ATAPIRequestTests : XCTestCase

@property (strong, nonatomic) ATAPIRequest *request;
@property (strong, nonatomic) ATURLConnection *connection;

@end

@implementation ATAPIRequestTests

- (void)setUp {
    [super setUp];

	self.self.request = [[ATAPIRequest alloc] init];
	self.connection = [[ATURLConnection alloc] init];
}

- (void)testConnectionFinishedSuccessfully {
	[self.connection setValue:@100 forKey:@"statusCode"];

	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertFalse(self.request.failed, @"self.request with 100 status code should succeed");

	[self.connection setValue:@200 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertFalse(self.request.failed, @"self.request with 200 status code should succeed");

	[self.connection setValue:@399 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertFalse(self.request.failed, @"self.request with 399 status code should succeed");

	[self.connection setValue:@400 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertTrue(self.request.failed, @"self.request with 400 status code should fail");
	XCTAssertFalse(self.request.shouldRetry, @"self.request with 400 status code should not retry");

	[self.connection setValue:@499 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertTrue(self.request.failed, @"self.request with 499 status code should fail");
	XCTAssertFalse(self.request.shouldRetry, @"self.request with 499 status code should not retry");

	[self.connection setValue:@500 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertTrue(self.request.failed, @"self.request with 500 status code should fail");
	XCTAssertTrue(self.request.shouldRetry, @"self.request with 500 status code should retry");

	[self.connection setValue:@599 forKey:@"statusCode"];
	[self.request connectionFinishedSuccessfully:self.connection];
	XCTAssertTrue(self.request.failed, @"self.request with 599 status code should fail");
	XCTAssertTrue(self.request.shouldRetry, @"self.request with 599 status code should retry");
}

@end
