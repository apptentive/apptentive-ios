//
//  ATInteractionUsageDataTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/15/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "ATConnect_Private.h"
#import "ATEngagementBackend.h"
#import "ATInteractionInvocation.h"
#import "ATInteractionUsageData.h"
#import "ATPersonInfo.h"
#import "ATBackend.h"

@interface ATInteractionUsageDataTests : XCTestCase

@end


@implementation ATInteractionUsageDataTests

- (void)testApplicationVersion {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"application/version": @{@"$eq": @{@"_type": @"version", @"version": @"4.0.0"}} };

	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] initWithEngagementData:@{ ATEngagementApplicationVersionKey: @"2" }];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/version"];
	XCTAssertNotNil(versionValue, @"No application/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"2");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usage], @"4.0.0 is not 2");

	usage = [[ATInteractionUsageData alloc] initWithEngagementData:@{ ATEngagementApplicationVersionKey: @"4.0" }];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usage], @"4.0 is like 4.0.0");
}

- (void)testDefaultApplicationVersion {
	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] init];

	id mockedUsage = OCMPartialMock(usage);
	OCMStub([mockedUsage applicationVersion]).andReturn(nil);

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/version"];
	XCTAssertNotNil(versionValue, @"No application/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"0.0.0");
}

- (void)testSDKVersion {
	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"sdk/version"];
	XCTAssertNotNil(versionValue, @"No sdk/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], kATConnectVersionString);
}

- (void)testCurrentTime {
	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *currentTimeValue = evaluationDictionary[@"current_time"];
	XCTAssertNotNil(currentTimeValue, @"No current_time key found.");
	XCTAssertEqualObjects(currentTimeValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([currentTimeValue[@"sec"] floatValue], usage.currentTime.floatValue, 0.001);
}

- (void)testTimeAtInstall {
	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] initWithEngagementData:@{ ATEngagementInstallDateKey: [NSDate date] }];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *timeAtInstallValue = evaluationDictionary[@"time_at_install/total"];
	XCTAssertNotNil(timeAtInstallValue, @"No time_at_install/total key found.");
	XCTAssertEqualObjects(timeAtInstallValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([timeAtInstallValue[@"sec"] doubleValue], usage.timeAtInstallTotal.timeIntervalSince1970, 0.1);

	NSDictionary *timeAtInstallVersionValue = evaluationDictionary[@"time_at_install/version"];
	XCTAssertNotNil(timeAtInstallVersionValue, @"No time_at_install/version key found.");
	XCTAssertEqualObjects(timeAtInstallVersionValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([timeAtInstallVersionValue[@"sec"] doubleValue], usage.timeAtInstallVersion.timeIntervalSince1970, 0.1);
}

//TODO: Test for code point last_invoked_at/total
//TODO: Test for interaction last_invoked_at/total

- (void)testPerson {
	[ATConnect sharedConnection].apiKey = @"123"; // Set up backend

	ATPersonInfo *person = [ATConnect sharedConnection].backend.currentPerson;
	person.name = nil;
	person.emailAddress = nil;

	ATInteractionUsageData *usage = [[ATInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	XCTAssertNil(evaluationDictionary[@"person/name"]);
	XCTAssertNil(evaluationDictionary[@"person/email"]);

	person.name = @"Andrew";
	person.emailAddress = @"example@example.com";

	NSDictionary *validEvaluationDictionary = [usage predicateEvaluationDictionary];
	XCTAssertEqualObjects(validEvaluationDictionary[@"person/name"], @"Andrew");
	XCTAssertEqualObjects(validEvaluationDictionary[@"person/email"], @"example@example.com");

	person.name = nil;
	person.emailAddress = nil;
}
@end
