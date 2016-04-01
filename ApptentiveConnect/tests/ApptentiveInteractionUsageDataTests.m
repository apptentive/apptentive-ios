//
//  ATInteractionUsageDataTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/15/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "Apptentive_Private.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentivePersonInfo.h"


@interface ApptentiveInteractionUsageDataTests : XCTestCase

@end


@implementation ApptentiveInteractionUsageDataTests

- (void)testApplicationVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"application/version": @{@"$eq": @{@"_type": @"version", @"version": @"4.0.0"}} };

	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];
	usage.applicationVersion = @"2";

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/version"];
	XCTAssertNotNil(versionValue, @"No application/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"2");

	XCTAssertFalse([invocation criteriaAreMetForUsageData:usage], @"4.0.0 is not 2");
	usage.applicationVersion = @"4.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usage], @"4.0 is like 4.0.0");
}

- (void)testDefaultApplicationVersion {
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

	id mockedUsage = OCMPartialMock(usage);
	OCMStub([mockedUsage applicationVersion]).andReturn(nil);

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/version"];
	XCTAssertNotNil(versionValue, @"No application/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"0.0.0");
}

- (void)testSDKVersion {
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"sdk/version"];
	XCTAssertNotNil(versionValue, @"No sdk/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], kApptentiveVersionString);
}

- (void)testDefaultSDKVersion {
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

	id mockedUsage = OCMPartialMock(usage);
	OCMStub([mockedUsage sdkVersion]).andReturn(nil);

	// Should fail to build the evaluation dictionary if there's no sdk version.
	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	XCTAssertNil(evaluationDictionary);
}

- (void)testCurrentTime {
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *currentTimeValue = evaluationDictionary[@"current_time"];
	XCTAssertNotNil(currentTimeValue, @"No current_time key found.");
	XCTAssertEqualObjects(currentTimeValue[@"_type"], @"datetime");
	XCTAssertEqualObjects(currentTimeValue[@"sec"], usage.currentTime);
}

- (void)testTimeAtInstall {
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *timeAtInstallValue = evaluationDictionary[@"time_at_install/total"];
	XCTAssertNotNil(timeAtInstallValue, @"No time_at_install/total key found.");
	XCTAssertEqualObjects(timeAtInstallValue[@"_type"], @"datetime");
	XCTAssertEqualObjects(timeAtInstallValue[@"sec"], @([usage.timeAtInstallTotal timeIntervalSince1970]));

	NSDictionary *timeAtInstallVersionValue = evaluationDictionary[@"time_at_install/version"];
	XCTAssertNotNil(timeAtInstallVersionValue, @"No time_at_install/version key found.");
	XCTAssertEqualObjects(timeAtInstallVersionValue[@"_type"], @"datetime");
	XCTAssertEqualObjects(timeAtInstallVersionValue[@"sec"], @([usage.timeAtInstallVersion timeIntervalSince1970]));
}

//TODO: Test for code point last_invoked_at/total
//TODO: Test for interaction last_invoked_at/total

- (void)testPerson {
	ApptentivePersonInfo *person = [ApptentivePersonInfo currentPerson];
	person.name = nil;
	person.emailAddress = nil;

	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] init];

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
