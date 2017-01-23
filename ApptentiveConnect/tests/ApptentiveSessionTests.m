//
//  ApptentiveSessionTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/23/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveSession.h"

@interface ApptentiveSessionTests : XCTestCase

@property (strong, nonatomic) ApptentiveSession *session;

@end

@implementation ApptentiveSessionTests

- (void)setUp {
    [super setUp];

	self.session = [[ApptentiveSession alloc] initWithAPIKey:@"ABC123"];
}

- (void)testAPIKey {
	XCTAssertEqualObjects(self.session.APIKey, @"ABC123", @"API key should be set");
}

@end
