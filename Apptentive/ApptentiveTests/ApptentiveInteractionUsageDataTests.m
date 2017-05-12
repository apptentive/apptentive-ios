//
//  ApptentiveInteractionUsageDataTests.m
//  Apptentive
//
//  Created by Andrew Wooster on 11/15/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Apptentive_Private.h"
#import "Apptentive+Debugging.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveConversation.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveVersion.h"
#import "ApptentiveBackend.h"
#import "ApptentivePerson.h"


@interface ApptentiveInteractionUsageDataTests : XCTestCase

@property (strong, nonatomic) ApptentiveInteractionUsageData *usage;

@end


@implementation ApptentiveInteractionUsageDataTests

- (void)setUp {
	[super setUp];

	self.usage = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] init]];
}

- (void)testApplicationVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"application/cf_bundle_short_version_string": @{@"$eq": @{@"_type": @"version", @"version": @"4.0.0"}} };

	[self.usage.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"2"] forKey:@"version"];

	NSDictionary *evaluationDictionary = [self.usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/cf_bundle_short_version_string"];
	XCTAssertNotNil(versionValue, @"No application/cf_bundle_short_version_string key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"2");

	XCTAssertFalse([invocation criteriaAreMetForConversation:self.usage.conversation], @"4.0.0 is not 2");
	[self.usage.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"4.0"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:self.usage.conversation], @"4.0 is like 4.0.0");
}

- (void)testDefaultApplicationVersion {
	NSDictionary *evaluationDictionary = [self.usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"application/cf_bundle_short_version_string"];
	XCTAssertNotNil(versionValue, @"No application/cf_bundle_short_version_string key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], @"0.0.0");
}

- (void)testSDKVersion {
	ApptentiveConfiguration *configuration = [ApptentiveConfiguration configurationWithApptentiveKey:@"app-key" apptentiveSignature:@"app-signature"];
	[Apptentive registerWithConfiguration:configuration];
	sleep(1);
	ApptentiveInteractionUsageData *usage = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] init]];

	NSDictionary *evaluationDictionary = [usage predicateEvaluationDictionary];
	NSDictionary *versionValue = evaluationDictionary[@"sdk/version"];
	XCTAssertNotNil(versionValue, @"No sdk/version key found.");
	XCTAssertEqualObjects(versionValue[@"_type"], @"version");
	XCTAssertEqualObjects(versionValue[@"version"], Apptentive.shared.SDKVersion);
}

- (void)testCurrentTime {
	NSDictionary *evaluationDictionary = [self.usage predicateEvaluationDictionary];
	NSDictionary *currentTimeValue = evaluationDictionary[@"current_time"];
	XCTAssertNotNil(currentTimeValue, @"No current_time key found.");
	XCTAssertEqualObjects(currentTimeValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([currentTimeValue[@"sec"] doubleValue], self.usage.conversation.currentTime.timeIntervalSince1970, 0.01);
}

- (void)testTimeAtInstall {
	NSDictionary *evaluationDictionary = [self.usage predicateEvaluationDictionary];
	NSDictionary *timeAtInstallValue = evaluationDictionary[@"time_at_install/total"];
	XCTAssertNotNil(timeAtInstallValue, @"No time_at_install/total key found.");
	XCTAssertEqualObjects(timeAtInstallValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([timeAtInstallValue[@"sec"] doubleValue], self.usage.conversation.appRelease.timeAtInstallTotal.timeIntervalSince1970, 0.01);

	NSDictionary *timeAtInstallVersionValue = evaluationDictionary[@"time_at_install/cf_bundle_short_version_string"];
	XCTAssertNotNil(timeAtInstallVersionValue, @"No time_at_install/version key found.");
	XCTAssertEqualObjects(timeAtInstallVersionValue[@"_type"], @"datetime");
	XCTAssertEqualWithAccuracy([timeAtInstallVersionValue[@"sec"] doubleValue], self.usage.conversation.appRelease.timeAtInstallVersion.timeIntervalSince1970, 0.01);
}

//TODO: Test for code point last_invoked_at/total
//TODO: Test for interaction last_invoked_at/total

- (void)testPerson {
	self.usage.conversation.person.name = nil;
	self.usage.conversation.person.emailAddress = nil;

	NSDictionary *evaluationDictionary = [self.usage predicateEvaluationDictionary];
	XCTAssertNil(evaluationDictionary[@"person/name"]);
	XCTAssertNil(evaluationDictionary[@"person/email"]);

	self.usage.conversation.person.name = @"Andrew";
	self.usage.conversation.person.emailAddress = @"example@example.com";

	NSDictionary *validEvaluationDictionary = [self.usage predicateEvaluationDictionary];
	XCTAssertEqualObjects(validEvaluationDictionary[@"person/name"], @"Andrew");
	XCTAssertEqualObjects(validEvaluationDictionary[@"person/email"], @"example@example.com");
}

@end
