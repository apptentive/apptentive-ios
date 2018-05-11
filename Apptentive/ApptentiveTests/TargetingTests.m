//
//  TargetingTests.m
//  ApptentiveTests
//
//  Created by Frank Schmitt on 3/6/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveTargets.h"
#import "ApptentiveConversation.h"

@interface TargetingTests : XCTestCase

@end


@implementation TargetingTests

- (void)testInvalidFormats {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
#pragma clang diagnostic ignored "-Wobjc-literal-conversion"
	@try {
		XCTAssertNil(([[ApptentiveTargets alloc] initWithTargetsDictionary:@[@"foo", @"bar", @"baz"]]));
		XCTAssertNil([[ApptentiveTargets alloc] initWithTargetsDictionary:@"foo"]);
		XCTAssertNil([[ApptentiveTargets alloc] initWithTargetsDictionary:nil]);

		ApptentiveTargets *targets = [[ApptentiveTargets alloc] initWithTargetsDictionary:@{@"foo": @{@"bar": @"baz"}}];
		XCTAssertNotNil(targets);
		XCTAssertEqual(targets.invocations.count, 0);

	} @catch (NSException *e) {
		XCTFail(@"Caught exception");
	}
#pragma clang diagnostic pop
}

- (void)testValidFormat {
	@try {
		ApptentiveTargets *targets = [[ApptentiveTargets alloc] initWithTargetsDictionary:@{@"event_1": @[@{ @"interaction_id": @"abc123", @"criteria": @{}}]}];

		XCTAssertNotNil(targets);
		XCTAssertEqual(targets.invocations.count, 1);
		XCTAssertEqualObjects([targets interactionIdentifierForEvent:@"event_1" conversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]], @"abc123");
	} @catch (NSException *e) {
		XCTFail(@"Caught exception");
	}
}

- (void)testArchiving {
	@try {
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[[ApptentiveTargets alloc] initWithTargetsDictionary:@{@"event_1": @[@{ @"interaction_id": @"abc123", @"criteria": @{}}]}]];
		ApptentiveTargets *targets = [NSKeyedUnarchiver unarchiveObjectWithData:data];

		XCTAssertNotNil(targets);
		XCTAssertEqual(targets.invocations.count, 1);
		XCTAssertEqualObjects([targets interactionIdentifierForEvent:@"event_1" conversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]], @"abc123");
	} @catch (NSException *e) {
		XCTFail(@"Caught exception");
	}
}

@end
