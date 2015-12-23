//
//  ATEngagementTests.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementTests.h"
#import "ATConnect.h"
#import "ATInteraction.h"
#import "ATInteractionInvocation.h"
#import "ATInteractionUsageData.h"
#import "ATEngagementBackend.h"
#import "ATEngagementManifestParser.h"
#import "ATConnect_Private.h"


@implementation ATEngagementTests

/*
 time_since_install/total - The total time in seconds since the app was installed (double)
 time_since_install/version - The total time in seconds since the current app version name was installed (double)
 time_since_install/build - The total time in seconds since the current app build number was installed (double)
 
 application_version - The currently running application version (string).
 application_build - The currently running application build "number" (string).
 current_time - The current time as a numeric Unix timestamp in seconds.
 
 app_release/version - The currently running application version (string).
 app_release/build - The currently running application build "number" (string).
 
 sdk/version - The currently running SDK version (string).
 sdk/distribution - The current SDK distribution, if available (string).
 sdk/distribution_version - The current version of the SDK distribution, if available (string).
 
 is_update/version - Returns true if we have seen a version prior to the current one.
 is_update/build - Returns true if we have seen a build prior to the current one.
 
 code_point.code_point_name.invokes.total - The total number of times code_point_name has been invoked across all versions of the app (regardless if an Interaction was shown at that point)  (integer)
 code_point.code_point_name.invokes.version - The number of times code_point_name has been invoked in the current version of the app (regardless if an Interaction was shown at that point) (integer)
 interactions.interaction_instance_id.invokes.total - The number of times the Interaction Instance with id interaction_instance_id has been invoked (irrespective of app version) (integer)
 interactions.interaction_instance_id.invokes.version  - The number of times the Interaction Instance with id interaction_instance_id has been invoked within the current version of the app (integer)
*/

- (void)testEventLabelsContainingCodePointSeparatorCharacters {
	//Escape "%", "/", and "#".

	NSString *i, *o;
	i = @"testEventLabelSeparators";
	o = @"testEventLabelSeparators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event#Label#Separators";
	o = @"test%23Event%23Label%23Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test/Event/Label/Separators";
	o = @"test%2FEvent%2FLabel%2FSeparators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%Event/Label#Separators";
	o = @"test%25Event%2FLabel%23Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event/Label%Separators";
	o = @"test%23Event%2FLabel%25Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test###Event///Label%%%Separators";
	o = @"test%23%23%23Event%2F%2F%2FLabel%25%25%25Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#%///#%//%%/#Event_!@#$%^&*(){}Label1234567890[]`~Separators";
	o = @"test%23%25%2F%2F%2F%23%25%2F%2F%25%25%2F%23Event_!@%23$%25^&*(){}Label1234567890[]`~Separators";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%/#";
	o = @"test%25%2F%23";
	XCTAssertTrue([[ATEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");
}

- (void)testInteractionCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_since_install/total": @{@"$gt": @(5 * 60 * 60 * 24), @"$lt": @(7 * 60 * 60 * 24)} };

	ATInteractionUsageData *usageData = [ATInteractionUsageData usageData];
	usageData.timeSinceInstallTotal = @(6 * 60 * 60 * 24);
	usageData.timeSinceInstallVersion = @(6 * 60 * 60 * 24);
	usageData.timeSinceInstallBuild = @(6 * 60 * 60 * 24);
	usageData.applicationVersion = @"1.8.9";
	usageData.applicationBuild = @"39";
	usageData.isUpdateVersion = @NO;
	usageData.isUpdateBuild = @NO;
	usageData.codePointInvokesTotal = @{};
	usageData.codePointInvokesVersion = @{};
	usageData.codePointInvokesTimeAgo = @{};
	usageData.interactionInvokesTotal = @{};
	usageData.interactionInvokesVersion = @{};
	usageData.interactionInvokesTimeAgo = @{};

	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_since_install/total": @(6 * 60 * 60 * 24),
		@"time_since_install/version": @(6 * 60 * 60 * 24) };

	ATInteractionUsageData *usageData = [ATInteractionUsageData usageData];
	usageData.timeSinceInstallTotal = @(6 * 60 * 60 * 24);
	usageData.timeSinceInstallVersion = @(6 * 60 * 60 * 24);
	usageData.timeSinceInstallBuild = @(6 * 60 * 60 * 24);
	usageData.applicationVersion = @"1.8.9";
	usageData.applicationBuild = @"39";
	usageData.isUpdateVersion = @NO;
	usageData.isUpdateBuild = @NO;
	usageData.codePointInvokesTotal = @{};
	usageData.codePointInvokesVersion = @{};
	usageData.codePointInvokesTimeAgo = @{};
	usageData.interactionInvokesTotal = @{};
	usageData.interactionInvokesVersion = @{};
	usageData.interactionInvokesTimeAgo = @{};
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"All keys are known, thus the criteria is met.");

	invocation.criteria = @{ @"time_since_install/total": @6,
		@"unknown_key": @"criteria_should_not_be_met" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");

	invocation.criteria = @{ @6: @"this is weird" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = nil;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Dictionary with nil criteria should evaluate to False.");

	invocation.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Dictionary with Null criteria should evaluate to False.");

	invocation.criteria = @{};
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Empty criteria dictionary with no keys should evaluate to True.");

	invocation.criteria = @{ @"": @6 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	invocation.criteria = @{ @"time_since_install/total": @(6 * dayTimeInterval) };
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(7 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");

	invocation.criteria = @{ @"time_since_install/total": @{@"$gt": @(5 * dayTimeInterval), @"$lt": @(7 * dayTimeInterval)} };
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(7 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");

	invocation.criteria = @{ @"time_since_install/total": @{@"$lte": @(5 * dayTimeInterval), @"$gt": @(3 * dayTimeInterval)} };
	usageData.timeSinceInstallTotal = @(3 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(4 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Install date");


	invocation.criteria = @{ @"time_since_install/total": @{@"$lte": @"5", @"$gt": @"3"} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaVersion {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"application_version": @"1.2.8" };
	usageData.applicationVersion = @"1.2.8";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"application_version": @"v3.0" };
	usageData.applicationVersion = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"app_release/version": @"1.2.8" };
	usageData.applicationVersion = @"1.2.8";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/version": @"v3.0" };
	usageData.applicationVersion = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");


	invocation.criteria = @{ @"app_release/version": @{@"$gt": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaBuild {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"application_build": @"39" };
	usageData.applicationBuild = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	usageData.applicationBuild = @"v39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application_build": @"v3.0" };
	usageData.applicationBuild = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	usageData.applicationBuild = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"app_release/build": @"39" };
	usageData.applicationBuild = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	usageData.applicationBuild = @"v39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"app_release/build": @"v3.0" };
	usageData.applicationBuild = @"v3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Build number");

	usageData.applicationBuild = @"3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");


	invocation.criteria = @{ @"app_release/build": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaSDK {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"sdk/version": [ATConnect versionObjectWithVersion:kATConnectVersionString] };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Default value should be current version.");

	invocation.criteria = @{ @"sdk/version": [ATConnect versionObjectWithVersion:@"1.4.2"] };
	usageData.sdkVersion = @"1.4.2";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Version should be 1.4.2");

	usageData.sdkVersion = @"1.4";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.4");

	usageData.sdkVersion = @"1.5.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.5.0");

	invocation.criteria = @{ @"sdk/version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");

	invocation.criteria = @{ @"sdk/distribution": @"CocoaPods-Source" };
	usageData.sdkDistribution = @"CocoaPods-Source";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution should be CocoaPods-Source");

	invocation.criteria = @{ @"sdk/distribution": @{@"$contains": @"CocoaPods"} };
	usageData.sdkDistribution = @"CocoaPods-Source";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution should contain CocoaPods");

	invocation.criteria = @{ @"sdk/distribution_version": @"foo" };
	usageData.sdkDistributionVersion = @"foo";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"SDK Distribution Version should match.");
}

- (void)testInteractionCriteriaCurrentTime {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"current_time": @{@"$exists": @YES} };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.currentTime doubleValue];
	XCTAssertTrue(timestamp < currentTimestamp && timestamp > (currentTimestamp - 5), @"Current time not a believable value.");

	invocation.criteria = @{ @"current_time": @{@"$gt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:1397598108.63843]]} };
	usageData.currentTime = @1397598109;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$lt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:1183135260]], @"$gt": [ATConnect timestampObjectWithDate:[NSDate dateWithTimeIntervalSince1970:465498000]]} };
	usageData.currentTime = @1183135259.5;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$gt": @"1183135260"} };
	usageData.currentTime = @1397598109;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because of type but not crash.");

	invocation.criteria = @{ @"current_time": @"1397598109" };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testCodePointInvokesVersion {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"This version has been invoked 1 time.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @0 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @2 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");


	invocation.criteria = @{ @"code_point/big.win/invokes/version": @7 };
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @7 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @19 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	invocation.criteria = @{ @"code_point/big.win/invokes/version": @{@"$gte": @5, @"$lte": @5} };
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @5 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @3 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @19 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");


	invocation.criteria = @{ @"code_point/big.win/invokes/version": @{@"$gte": @"5", @"$lte": @"5"} };
	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/version": @5 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testUpgradeMessageCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"code_point/app.launch/invokes/version": @1,
		@"application_version": @"1.3.0",
		@"application_build": @"39" };
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message without build number.");
	usageData.applicationBuild = @"39";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @2 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.applicationVersion = @"1.3.1";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application_version": @"1.3.0",
		@"code_point/app.launch/invokes/version": @{@"$gte": @1} };
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @2 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @0 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application_version": @"1.3.0",
		@"code_point/app.launch/invokes/version": @{@"$lte": @4} };
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @4 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @5 };
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");


	invocation.criteria = @{ @"code_point/app.launch/invokes/version": @[@1],
		@"application_version": @"1.3.0",
		@"application_build": @"39" };
	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/version": @1 };
	usageData.applicationVersion = @"1.3.0";
	usageData.applicationBuild = @"39";
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testNewUpgradeMessageCriteria {
	NSString *jsonString = @"{\"interactions\":[{\"id\":\"52fadf097724c5c09f000012\",\"type\":\"UpgradeMessage\",\"configuration\":{}}],\"targets\":{\"local#app#upgrade_message_test\":[{\"interaction_id\":\"52fadf097724c5c09f000012\",\"criteria\":{\"application_version\":\"999\",\"time_since_install/version\":{\"$lt\":604800},\"is_update/version\":true,\"interactions/52fadf097724c5c09f000012/invokes/total\":0}}]}}";

	/*
	targets = {
		"local#app#upgrade_message_test" = (
											{
												criteria = {
													"application_version" = 999;
													"interactions/52fadf097724c5c09f000012/invokes/total" = 0;
													"is_update/version" = 1;
													"time_since_install/version" = {
														"$lt" = 604800;
													};
												};
												"interaction_id" = 52fadf097724c5c09f000012;
											}
											);
	};
	*/

	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];

	NSDictionary *targetsDictionary = jsonDictionary[@"targets"];

	NSString *targetedEvent = [[ATInteraction localAppInteraction] codePointForEvent:@"upgrade_message_test"];
	NSDictionary *appLaunchInteraction = [[targetsDictionary objectForKey:targetedEvent] objectAtIndex:0];

	ATInteractionInvocation *upgradeMessageInteractionInvocation = [ATInteractionInvocation invocationWithJSONDictionary:appLaunchInteraction];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertTrue([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria met!");

	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"998";
	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");

	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
	usageData.isUpdateVersion = @NO;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");

	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @1 };
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");
}

- (void)testComplexCriteria {
	NSDictionary *complexCriteria = @{ @"$or": @[@{@"time_since_install/version": @{@"$lt": @(259200)}},
		@{@"$and": @[@{@"code_point/app.launch/invokes/total": @2},
			@{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @0},
			@{@"$or": @[@{@"code_point/small.win/invokes/total": @2},
				@{@"code_point/big.win/invokes/total": @2}]}]}]
	};

	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = complexCriteria;

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	usageData.timeSinceInstallVersion = @(2 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"2 satisfies the inital OR clause; passes regardless of the next condition.");
	usageData.timeSinceInstallVersion = @(0 * dayTimeInterval);
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"0 satisfies the inital OR clause; passes regardless of the next condition.");

	usageData.timeSinceInstallVersion = @(3 * dayTimeInterval);
	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @8 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"3 fails the initial OR clause. 8 fails the other clause.");

	usageData.timeSinceInstallVersion = @(3 * dayTimeInterval);
	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @0 };
	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
		@"code_point/small.win/invokes/total": @0,
		@"code_point/big.win/invokes/total": @2 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
		@"code_point/small.win/invokes/total": @2,
		@"code_point/big.win/invokes/total": @19 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
		@"code_point/small.win/invokes/total": @19,
		@"code_point/big.win/invokes/total": @19 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Neither of the last two ORed code_point totals are right.");
	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
		@"code_point/small.win/invokes/total": @2,
		@"code_point/big.win/invokes/total": @1 };
	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @8 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"The middle case is incorrect.");
}

- (void)testTimeAgoCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @100,
		@"interactions/big.win/invokes/time_ago": @1000 };

	usageData.codePointInvokesTimeAgo = @{ @"code_point/app.launch/invokes/time_ago": @100 };
	usageData.interactionInvokesTimeAgo = @{ @"interactions/big.win/invokes/time_ago": @1000 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");


	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500},
		@"interactions/big.win/invokes/time_ago": @{@"$lte": @1000} };
	usageData.codePointInvokesTimeAgo = @{ @"code_point/app.launch/invokes/time_ago": @800 };
	usageData.interactionInvokesTimeAgo = @{ @"interactions/big.win/invokes/time_ago": @100 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoCodePointCriteriaViaDatesInNSUserDefaults {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$lte": @500} };
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"app.launch": [NSDate distantPast] } forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500} };
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"app.launch": [NSDate distantPast] } forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500} };
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"app.launch": [NSDate dateWithTimeIntervalSinceNow:-600] } forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500} };
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400] } forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500} };
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501] } forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoInteractionCriteriaViaDatesInNSUserDefaults {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$lte": @500} };
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"526fe2836dd8bf546a00000b": [NSDate distantPast] } forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500} };
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"526fe2836dd8bf546a00000b": [NSDate distantPast] } forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500} };
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"526fe2836dd8bf546a00000b": [NSDate dateWithTimeIntervalSinceNow:-600] } forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500} };
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400] } forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500} };
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{ @"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501] } forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testIsUpdateVersionsAndBuilds {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	//Version
	invocation.criteria = @{ @"is_update/version": @YES };
	usageData.isUpdateVersion = @YES;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @NO };
	usageData.isUpdateVersion = @NO;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @YES };
	usageData.isUpdateVersion = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/version": @NO };
	usageData.isUpdateVersion = @YES;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	//Build
	invocation.criteria = @{ @"is_update/build": @YES };
	usageData.isUpdateBuild = @YES;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @NO };
	usageData.isUpdateBuild = @NO;
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @YES };
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/build": @NO };
	usageData.isUpdateBuild = @YES;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Test isUpdate");


	invocation.criteria = @{ @"is_update/build": @[[NSNull null]] };
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
	invocation.criteria = @{ @"is_update/build": @{@"$gt": @"lajd;fl ajsd;flj"} };
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInvokesVersion {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$gte": @6} };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };
	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes version");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6} };
	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @7 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes version");
}

- (void)testInvokesBuild {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$gte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	usageData.interactionInvokesBuild = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Invokes build");

	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	usageData.interactionInvokesBuild = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @7 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Invokes build");
}

- (void)testEnjoymentDialogCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"$or": @[@{@"code_point/local#app#init/invokes/version": @{@"$gte": @10}},
		@{@"time_since_install/total": @{@"$gt": @864000}},
		@{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt": @10}}],
		@"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");


	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/version": @9 };
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @9 };
	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"The OR clauses are failing.");

	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/version": @11 };
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @9 };
	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");

	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/version": @11 };
	usageData.timeSinceInstallTotal = @864001;
	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @11 };
	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");

	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");
}

- (void)testNotInCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"$and": @[@{@"code_point/local#app#init/invokes/version": @{@"$not": @{@"$gte": @10}}},
		@{@"time_since_install/total": @{@"$not": @{@"$gt": @864000}}},
		@{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt": @10}}],
		@"interactions/533ed97a7724c5457e00003f/invokes/version": @0
	};
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");

	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/version": @9 };
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @9 };
	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/version": @0 };
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail due to invokes/version being 9.");

	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @11 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass due to invokes being 11.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$not": @{@"$gt": @6}} };
	usageData.interactionInvokesBuild = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @1 };
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because 6 is not > 1.");
}

- (void)testContainsCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$contains": @"a"} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because a is in 1.2.3a");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$contains": @"1.4"} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because 1.4 is not in 1.2.3a");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$contains": @"abc"} };
	usageData.applicationVersion = @"AbC";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Contains should be case insensitive.");
}

- (void)testStartsWithCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$starts_with": @"1.2."} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because 1.2.3a starts with 1.2.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$starts_with": @"1.4"} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because 1.2.3a doesn't start with 1.4");

	// Test directionality.
	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$starts_with": @"abcd"} };
	usageData.applicationVersion = @"abc";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because abc doesn't start with abcd.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$starts_with": @"abc"} };
	usageData.applicationVersion = @"AbCdEF";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"starts_with should be case insensitive.");
}

- (void)testEndsWithCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$ends_with": @"a"} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because 1.2.3a ends with a");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$ends_with": @"1.4"} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because 1.2.3a doesn't end in 1.4");

	// Test directionality
	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$ends_with": @"abcd"} };
	usageData.applicationVersion = @"bcd";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because bcd doesn't end with abcd.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$ends_with": @"DEF"} };
	usageData.applicationVersion = @"AbCdEf";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Ends with should be case insensitive.");
}

- (void)testExistsCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$exists": @YES} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because application_version exists.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$exists": @YES} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because application_version doesn't exist.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_version": @{@"$exists": @NO} };
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([invocation criteriaAreMetForUsageData:usageData], @"Should fail because application_version exists.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_build": @{@"$exists": @NO} };
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because application_build doesn't exist.");

	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"application_build": @{@"$exists": @YES} };
	usageData.applicationBuild = @"nil";
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because application_build exists.");


	invocation = [[ATInteractionInvocation alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$exists": @YES},
		@"interactions/big.win/invokes/time_ago": @{@"$exists": @NO} };
	usageData.codePointInvokesTimeAgo = @{ @"code_point/app.launch/invokes/time_ago": @800 };
	usageData.interactionInvokesTimeAgo = @{};
	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([invocation criteriaAreMetForUsageData:usageData], @"Should pass because invokes/time_ago exists.");
}

- (void)testInvalidJSON {
	NSString *json = @"";
	ATEngagementManifestParser *parser = [[ATEngagementManifestParser alloc] init];

	NSDictionary *targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertNil(targetsAndInteractions, @"Interactions should be nil");

	json = @"[]";
	targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertNil(targetsAndInteractions, @"Interactions should be nil");

	json = @"{}";
	targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	NSDictionary *targets = targetsAndInteractions[@"targets"];
	XCTAssertEqualObjects(@{}, targets, @"Should be empty");
	NSDictionary *interactions = targetsAndInteractions[@"interactions"];
	XCTAssertEqualObjects(@{}, interactions, @"Should be empty");
}

- (void)testCustomDataAndExtendedData {
	UIViewController *dummyViewController = [[UIViewController alloc] init];

	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil fromViewController:dummyViewController], @"nil custom data should not throw exception!");
	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil withExtendedData:nil fromViewController:dummyViewController], @"nil custom data or extended data should not throw exception!");
}

- (void)testCustomDeviceDataCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomDeviceData:@"test_value" withKey:@"test_device_custom_data"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value",
		@"device/custom_data/test_version": @"4.5.1" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomDeviceData:@"4.5.1" withKey:@"test_version"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
}

- (void)testCustomPersonDataCriteria {
	ATInteractionInvocation *invocation = [[ATInteractionInvocation alloc] init];
	invocation.criteria = @{ @"person/custom_data/hair_color": @"black" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomPersonData:@"black" withKey:@"hair_color"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");

	invocation.criteria = @{ @"person/custom_data/hair_color": @"black",
		@"person/custom_data/age": @"27" };

	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomPersonData:@"27" withKey:@"age"];

	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
}

- (void)testCanShowInteractionForEvent {
	ATInteractionInvocation *canShow = [[ATInteractionInvocation alloc] init];
	canShow.criteria = @{};
	canShow.interactionID = @"example_interaction_ID";

	ATInteractionInvocation *willNotShow = [[ATInteractionInvocation alloc] init];
	willNotShow.criteria = @{ @"cannot_parse_criteria": @"cannot_parse_criteria" };
	willNotShow.interactionID = @"example_interaction_ID";

	NSDictionary *targets = @{ [[ATInteraction localAppInteraction] codePointForEvent:@"canShow"]: @[canShow],
		[[ATInteraction localAppInteraction] codePointForEvent:@"cannotShow"]: @[willNotShow]
	};

	NSDictionary *interactions = @{ @"example_interaction_ID": [[ATInteraction alloc] init] };

	[[ATConnect sharedConnection].engagementBackend didReceiveNewTargets:targets andInteractions:interactions maxAge:60];

	XCTAssertTrue([canShow criteriaAreMet], @"Invocation should be valid.");
	XCTAssertTrue([[ATConnect sharedConnection] canShowInteractionForEvent:@"canShow"], @"If invocation is valid, it will be shown for the next targeted event.");

	XCTAssertFalse([willNotShow criteriaAreMet], @"Invocation should not be valid.");
	XCTAssertFalse([[ATConnect sharedConnection] canShowInteractionForEvent:@"cannotShow"], @"If invocation is not valid, it will not be shown for the next targeted event.");
}

@end
