//
//  ApptentiveEngagementTests.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Apptentive.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveEngagementBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveSession.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"


@interface ApptentiveEngagementTests : XCTestCase
@end


@implementation ApptentiveEngagementTests

/*
 time_at_install/total - When the app was installed (NSDate, using $before or $after for comparison)
 time_at_install/version - When the app was upgraded (NSDate, using $before or $after for comparison)
 time_at_install/build - When the app was upgraded (NSDate, using $before or $after for comparison)

 application_version - The currently running application version (string).
 application_build - The currently running application build "number" (string).
 current_time - The current time as a numeric Unix timestamp in seconds.

 app_release/version - The currently running application version (string).
 app_release/build - The currently running application build "number" (string).
 app_release/debug - Whether the currently running application is a debug build (boolean).

 sdk/version - The currently running SDK version (string).
 sdk/distribution - The current SDK distribution, if available (string).
 sdk/distribution_version - The current version of the SDK distribution, if available (string).

 is_update/cf_bundle_short_version_string - Returns true if we have seen a version prior to the current one.
 is_update/cf_bundle_version - Returns true if we have seen a build prior to the current one.

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
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event#Label#Separators";
	o = @"test%23Event%23Label%23Separators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test/Event/Label/Separators";
	o = @"test%2FEvent%2FLabel%2FSeparators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%Event/Label#Separators";
	o = @"test%25Event%2FLabel%23Separators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event/Label%Separators";
	o = @"test%23Event%2FLabel%25Separators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test###Event///Label%%%Separators";
	o = @"test%23%23%23Event%2F%2F%2FLabel%25%25%25Separators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#%///#%//%%/#Event_!@#$%^&*(){}Label1234567890[]`~Separators";
	o = @"test%23%25%2F%2F%2F%23%25%2F%2F%25%25%2F%23Event_!@%23$%25^&*(){}Label1234567890[]`~Separators";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%/#";
	o = @"test%25%2F%23";
	XCTAssertTrue([[ApptentiveEngagementBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");
}

- (void)testInteractionCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_at_install/total": @{ @"$before": @(-5 * 60 * 60 * 24), @"$after": @(-7 * 60 * 60 * 24) } };

	ApptentiveInteractionUsageData *usageData = [ApptentiveInteractionUsageData usageDataWithSession:[[ApptentiveSession alloc] init]];

	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[usageData.session setValue:@NO forKey:@"updateVersion"];
	[usageData.session setValue:@NO forKey:@"updateBuild"];

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];
	
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_at_install/total": @{ @"$before": @(6 * 60 * 60 * 24) },
							 @"time_at_install/cf_bundle_short_version_string": @{ @"$before": @(6 * 60 * 60 * 24) } };

	ApptentiveInteractionUsageData *usageData = [ApptentiveInteractionUsageData usageDataWithSession:[[ApptentiveSession alloc] init]];

	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[usageData.session setValue:@NO forKey:@"updateVersion"];
	[usageData.session setValue:@NO forKey:@"updateBuild"];

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"All keys are known, thus the criteria is met.");

	invocation.criteria = @{ @"time_since_install/total": @6,
							 @"unknown_key": @"criteria_should_not_be_met" };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");

	invocation.criteria = @{ @6: @"this is weird" };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];

	invocation.criteria = nil;
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Dictionary with nil criteria should evaluate to False.");

	invocation.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Dictionary with Null criteria should evaluate to False.");

	invocation.criteria = @{};
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Empty criteria dictionary with no keys should evaluate to True.");

	invocation.criteria = @{ @"": @6 };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];

	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	invocation.criteria = @{ @"time_at_install/total": @{ @"$before": @(-6 * dayTimeInterval) } };
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -5 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");

	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-5 * dayTimeInterval), @"$after": @(-7 * dayTimeInterval)} };
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -6 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -4.999 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");
	[usageData.session setValue:[NSDate dateWithTimeIntervalSinceNow: -7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Install date");
}

- (void)testInteractionCriteriaDebug {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	// Debug default to false
	invocation.criteria = @{ @"application/debug": @NO };

	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Debug boolean");

	invocation.criteria = @{ @"application/debug": @YES };

	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Debug boolean");
}

- (void)testInteractionCriteriaVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.2.8"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Version number");
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v1.2.8"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/version": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"application/version not a valid key");

	invocation.criteria = @{ @"application/version_code": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"application/version not a valid key");
}

- (void)testInteractionCriteriaBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Build number");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v39"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Build number must not have a 'v' in front!");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"3.0"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Build number");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	invocation.criteria = @{ @"application/build": [Apptentive versionObjectWithVersion:@"3.0.0"] };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"application/build not a valid key");
}

- (void)testInteractionCriteriaSDK {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	invocation.criteria = @{ @"sdk/version": [Apptentive versionObjectWithVersion:@"1.4.2"] };
	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4.2"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"SDK Version should be 1.4.2");

	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"SDK Version isn't 1.4");

	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.5.0"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"SDK Version isn't 1.5.0");

	invocation.criteria = @{ @"sdk/version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaCurrentTime {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] init]];

	invocation.criteria = @{ @"current_time": @{@"$exists": @YES} };
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.session.currentTime timeIntervalSince1970];
	XCTAssertTrue(timestamp < (currentTimestamp + 0.5) && timestamp > (currentTimestamp - 0.5), @"Current time not a believable value.");

	invocation.criteria = @{ @"current_time": @{@"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-5]]} };
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$lt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:0.5]], @"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-0.5]]} };
	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$gt": @"1183135260"} };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail because of type but not crash.");

	invocation.criteria = @{ @"current_time": @"1397598109" };
	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
}

//- (void)testCodePointInvokesVersion {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"This version has been invoked 1 time.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @0 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @2 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//
//
//	invocation.criteria = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @7 };
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @7 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @19 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//
//	invocation.criteria = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @{@"$gte": @5, @"$lte": @5} };
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @5 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @3 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @19 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Codepoint version invokes.");
//
//	invocation.criteria = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @{@"$gte": @"5", @"$lte": @"5"} };
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @5 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
//
//	invocation.criteria = @{ @"code_point/big.win/invokes/version": @1 };
//	usageData.codePointInvokesVersion = @{ @"code_point/big.win/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid key.");
//
//	invocation.criteria = @{ @"interactions/big.win/invokes/version": @1 };
//	usageData.codePointInvokesVersion = @{ @"interactions/big.win/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid key.");
//}
//
//- (void)testUpgradeMessageCriteria {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1,
//							 @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.0"],
//							 @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message without build number.");
//	usageData.applicationCFBundleVersion = @"39";
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @2 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.1";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//
//	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.0"],
//							 @"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$gte": @1} };
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @2 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @0 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//
//	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.0"],
//							 @"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$lte": @4} };
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @4 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @5 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test Upgrade Message.");
//
//
//	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @[@1],
//							 @"application_version": @"1.3.0",
//							 @"application_build": @"39" };
//	usageData.codePointInvokesVersion = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
//	usageData.applicationCFBundleShortVersionString = @"1.3.0";
//	usageData.applicationCFBundleVersion = @"39";
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
//}

//- (void)testNewUpgradeMessageCriteria {
//	NSString *jsonString = @"{\"interactions\":[{\"id\":\"52fadf097724c5c09f000012\",\"type\":\"UpgradeMessage\",\"configuration\":{}}],\"targets\":{\"local#app#upgrade_message_test\":[{\"interaction_id\":\"52fadf097724c5c09f000012\",\"criteria\":{\"application/cf_bundle_short_version_string\":{\"_type\":\"version\",\"version\":\"999\"},\"time_at_install/cf_bundle_short_version_string\":{\"$after\":-604800},\"is_update/cf_bundle_short_version_string\":true,\"interactions/52fadf097724c5c09f000012/invokes/total\":0}}]}}";
//
//	/*
//	 targets = {
//		"local#app#upgrade_message_test" = (
//	 {
//	 criteria = {
//	 "application_version" = 999;
//	 "interactions/52fadf097724c5c09f000012/invokes/total" = 0;
//	 "is_update/cf_bundle_short_version_string" = 1;
//	 "time_at_install/version" = {
//	 "$before" = -604800;
//	 };
//	 };
//	 "interaction_id" = 52fadf097724c5c09f000012;
//	 }
//	 );
//	 };
//	 */
//
//	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//	NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
//
//	NSDictionary *targetsDictionary = jsonDictionary[@"targets"];
//
//	NSString *targetedEvent = [[ApptentiveInteraction localAppInteraction] codePointForEvent:@"upgrade_message_test"];
//	NSDictionary *appLaunchInteraction = [[targetsDictionary objectForKey:targetedEvent] objectAtIndex:0];
//
//	ApptentiveInteractionInvocation *upgradeMessageInteractionInvocation = [ApptentiveInteractionInvocation invocationWithJSONDictionary:appLaunchInteraction];
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	usageData.applicationCFBundleShortVersionString = @"999";
//	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
//	usageData.isUpdateVersion = @YES;
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
//	XCTAssertTrue([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Upgrade Message criteria met!");
//
//	usageData = [[ApptentiveInteractionUsageData alloc] init];
//	usageData.applicationCFBundleShortVersionString = @"998";
//	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
//	usageData.isUpdateVersion = @YES;
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
//	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Upgrade Message criteria not met!");
//
//	usageData = [[ApptentiveInteractionUsageData alloc] init];
//	usageData.applicationCFBundleShortVersionString = @"999";
//	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @0 };
//	usageData.isUpdateVersion = @NO;
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
//	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Upgrade Message criteria not met!");
//
//	usageData = [[ApptentiveInteractionUsageData alloc] init];
//	usageData.applicationCFBundleShortVersionString = @"999";
//	usageData.interactionInvokesTotal = @{ @"interactions/52fadf097724c5c09f000012/invokes/total": @1 };
//	usageData.isUpdateVersion = @YES;
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-2 * 24 * 60 * 60];
//	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Upgrade Message criteria not met!");
//
//	upgradeMessageInteractionInvocation.criteria = @{ @"time_at_install/version": @{ @"$before": @(-1 * 24 * 60 * 60) }};
//	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Bad key returns false");
//
//	upgradeMessageInteractionInvocation.criteria = @{ @"time_at_install/build": @{ @"$before": @(-1 * 24 * 60 * 60) }};
//	XCTAssertFalse([upgradeMessageInteractionInvocation criteriaAreMetForConsumerData:usageData.session], @"Bad key returns false");
//}
//
//- (void)testComplexCriteria {
//	NSDictionary *complexCriteria = @{ @"$or": @[@{@"time_at_install/cf_bundle_short_version_string": @{@"$after": @(-259200)}},
//												 @{@"$and": @[@{@"code_point/app.launch/invokes/total": @2},
//															  @{@"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @0},
//															  @{@"$or": @[@{@"code_point/small.win/invokes/total": @2},
//																		  @{@"code_point/big.win/invokes/total": @2}]}]}]
//									   };
//
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = complexCriteria;
//
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	NSTimeInterval dayTimeInterval = 60 * 60 * 24;
//
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-2 * dayTimeInterval];
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"2 satisfies the inital OR clause; passes regardless of the next condition.");
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:0 * dayTimeInterval];
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"0 satisfies the inital OR clause; passes regardless of the next condition.");
//
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-3 * dayTimeInterval];
//	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @8 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"3 fails the initial OR clause. 8 fails the other clause.");
//
//	usageData.timeAtInstallVersion = [NSDate dateWithTimeIntervalSinceNow:-3 * dayTimeInterval];
//	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @0 };
//	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
//										 @"code_point/small.win/invokes/total": @0,
//										 @"code_point/big.win/invokes/total": @2 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"complex");
//	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
//										 @"code_point/small.win/invokes/total": @2,
//										 @"code_point/big.win/invokes/total": @19 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"complex");
//	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
//										 @"code_point/small.win/invokes/total": @19,
//										 @"code_point/big.win/invokes/total": @19 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Neither of the last two ORed code_point totals are right.");
//	usageData.codePointInvokesTotal = @{ @"code_point/app.launch/invokes/total": @2,
//										 @"code_point/small.win/invokes/total": @2,
//										 @"code_point/big.win/invokes/total": @1 };
//	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @8 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"The middle case is incorrect.");
//}
//
//- (void)testTimeAgoCriteria {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @100,
//							 @"interactions/big.win/invokes/time_ago": @1000 };
//
//	usageData.codePointInvokesTimeAgo = @{ @"code_point/app.launch/invokes/time_ago": @100 };
//	usageData.interactionInvokesTimeAgo = @{ @"interactions/big.win/invokes/time_ago": @1000 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test timeAgo");
//
//
//	invocation.criteria = @{ @"code_point/app.launch/invokes/time_ago": @{@"$gte": @500},
//							 @"interactions/big.win/invokes/time_ago": @{@"$lte": @1000} };
//	usageData.codePointInvokesTimeAgo = @{ @"code_point/app.launch/invokes/time_ago": @800 };
//	usageData.interactionInvokesTimeAgo = @{ @"interactions/big.win/invokes/time_ago": @100 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test timeAgo");
//}
//
//- (void)testIsUpdateVersionsAndBuilds {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//
//	//Version
//	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
//	usageData.isUpdateVersion = @YES;
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
//	usageData.isUpdateVersion = @NO;
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
//	usageData.isUpdateVersion = @NO;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
//	usageData.isUpdateVersion = @YES;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	//Build
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
//	usageData.isUpdateBuild = @YES;
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
//	usageData.isUpdateBuild = @NO;
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
//	usageData.isUpdateBuild = @NO;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
//	usageData.isUpdateBuild = @YES;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Test isUpdate");
//
//
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @[[NSNull null]] };
//	usageData.isUpdateBuild = @NO;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
//	invocation.criteria = @{ @"is_update/cf_bundle_version": @{@"$gt": @"lajd;fl ajsd;flj"} };
//	usageData.isUpdateBuild = @NO;
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid types.");
//
//	usageData.isUpdateVersion = @NO;
//	usageData.isUpdateBuild = @NO;
//	invocation.criteria = @{ @"is_update/version_code": @NO };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid key.");
//
//	invocation.criteria = @{ @"is_update/version": @NO };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid key.");
//
//	invocation.criteria = @{ @"is_update/build": @NO };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Should fail with invalid key.");
//}
//
//- (void)testInvokesVersion {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @{@"$lte": @6} };
//
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes version should default to 0 when not set.");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @{@"$gte": @6} };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes version should default to 0 when not set.");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @{@"$lte": @6} };
//	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes version");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @{@"$lte": @6} };
//	usageData.interactionInvokesVersion = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @7 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes version");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @7} };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes version");
//}
//
//- (void)testInvokesBuild {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @{@"$lte": @6} };
//
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes build should default to 0 when not set.");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @{@"$gte": @6} };
//	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes build should default to 0 when not set.");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @{@"$lte": @6} };
//	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
//	usageData.interactionInvokesBuild = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @1 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes build");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @{@"$lte": @6} };
//	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
//	usageData.interactionInvokesBuild = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @7 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes build");
//
//	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @7} };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"Invokes build");
//}
//
//- (void)testEnjoymentDialogCriteria {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = @{ @"$or": @[@{@"code_point/local#app#init/invokes/cf_bundle_short_version_string": @{@"$gte": @10}},
//									   @{@"time_at_install/total": @{@"$before": @-864000}},
//									   @{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt": @10}}],
//							 @"interactions/533ed97a7724c5457e00003f/invokes/cf_bundle_short_version_string": @0 };
//	XCTAssertNotNil([invocation criteriaPredicate], @"Criteria should parse correctly.");
//
//
//	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];
//	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/cf_bundle_short_version_string": @9 };
//	usageData.timeAtInstallTotal = [NSDate dateWithTimeIntervalSinceNow:-863999];
//	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @9 };
//	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/cf_bundle_short_version_string": @0 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"The OR clauses are failing.");
//
//	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/cf_bundle_short_version_string": @11 };
//	usageData.timeAtInstallTotal = [NSDate dateWithTimeIntervalSinceNow:-863999];
//	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @9 };
//	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/cf_bundle_short_version_string": @0 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");
//
//	usageData.codePointInvokesVersion = @{ @"code_point/local#app#init/invokes/cf_bundle_short_version_string": @11 };
//	usageData.timeAtInstallTotal = [NSDate dateWithTimeIntervalSinceNow:-864001];
//	usageData.codePointInvokesTotal = @{ @"code_point/local#app#testRatingFlow/invokes/total": @11 };
//	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/cf_bundle_short_version_string": @0 };
//	XCTAssertTrue([invocation criteriaAreMetForConsumerData:usageData.session], @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");
//
//	usageData.interactionInvokesVersion = @{ @"interactions/533ed97a7724c5457e00003f/invokes/cf_bundle_short_version_string": @1 };
//	XCTAssertFalse([invocation criteriaAreMetForConsumerData:usageData.session], @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");
//}
//
//- (void)testInvalidJSON {
//	NSString *json = @"";
//	ApptentiveEngagementManifestParser *parser = [[ApptentiveEngagementManifestParser alloc] init];
//
//	NSDictionary *targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
//	XCTAssertNil(targetsAndInteractions, @"Interactions should be nil");
//
//	json = @"[]";
//	targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
//	XCTAssertNil(targetsAndInteractions, @"Interactions should be nil");
//
//	json = @"{}";
//	targetsAndInteractions = [parser targetsAndInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
//	NSDictionary *targets = targetsAndInteractions[@"targets"];
//	XCTAssertEqualObjects(@{}, targets, @"Should be empty");
//	NSDictionary *interactions = targetsAndInteractions[@"interactions"];
//	XCTAssertEqualObjects(@{}, interactions, @"Should be empty");
//}
//
//- (void)testCustomDataAndExtendedData {
//	UIViewController *dummyViewController = [[UIViewController alloc] init];
//
//	XCTAssertNoThrow([[Apptentive sharedConnection] engage:@"test_event" withCustomData:nil fromViewController:dummyViewController], @"nil custom data should not throw exception!");
//	XCTAssertNoThrow([[Apptentive sharedConnection] engage:@"test_event" withCustomData:nil withExtendedData:nil fromViewController:dummyViewController], @"nil custom data or extended data should not throw exception!");
//}
//
//- (void)testCustomDeviceDataCriteria {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value" };
//
//	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"test_device_custom_data"];
//	[[Apptentive sharedConnection] removeCustomDeviceDataWithKey:@"test_version"];
//
//	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");
//
//	[[Apptentive sharedConnection] addCustomDeviceData:@"test_value" withKey:@"test_device_custom_data"];
//
//	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
//
//	invocation.criteria = @{ @"device/custom_data/test_device_custom_data": @"test_value",
//							 @"device/custom_data/test_version": @"4.5.1" };
//
//	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");
//
//	[[Apptentive sharedConnection] addCustomDeviceData:@"4.5.1" withKey:@"test_version"];
//
//	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
//}
//
//- (void)testCustomPersonDataCriteria {
//	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
//	invocation.criteria = @{ @"person/custom_data/hair_color": @"black" };
//
//	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"hair_color"];
//	[[Apptentive sharedConnection] removeCustomPersonDataWithKey:@"age"];
//
//	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");
//
//	[[Apptentive sharedConnection] addCustomPersonData:@"black" withKey:@"hair_color"];
//
//	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
//
//	invocation.criteria = @{ @"person/custom_data/hair_color": @"black",
//							 @"person/custom_data/age": @"27" };
//
//	XCTAssertFalse([invocation criteriaAreMet], @"Criteria should not be met before adding custom data.");
//
//	[[Apptentive sharedConnection] addCustomPersonData:@"27" withKey:@"age"];
//
//	XCTAssertTrue([invocation criteriaAreMet], @"Criteria should be met after adding custom data.");
//}
//
//- (void)testCanShowInteractionForEvent {
//	[Apptentive sharedConnection].APIKey = @"bogus_api_key"; // trigger creation of engagement backend
//
//	ApptentiveInteractionInvocation *canShow = [[ApptentiveInteractionInvocation alloc] init];
//	canShow.criteria = @{};
//	canShow.interactionID = @"example_interaction_ID";
//
//	ApptentiveInteractionInvocation *willNotShow = [[ApptentiveInteractionInvocation alloc] init];
//	willNotShow.criteria = @{ @"cannot_parse_criteria": @"cannot_parse_criteria" };
//	willNotShow.interactionID = @"example_interaction_ID";
//
//	NSDictionary *targets = @{ [[ApptentiveInteraction localAppInteraction] codePointForEvent:@"canShow"]: @[canShow],
//							   [[ApptentiveInteraction localAppInteraction] codePointForEvent:@"cannotShow"]: @[willNotShow]
//							   };
//
//	NSDictionary *interactions = @{ @"example_interaction_ID": [[ApptentiveInteraction alloc] init] };
//
//	[[Apptentive sharedConnection].engagementBackend didReceiveNewTargets:targets andInteractions:interactions maxAge:60];
//
//	XCTAssertTrue([canShow criteriaAreMet], @"Invocation should be valid.");
//	XCTAssertTrue([[Apptentive sharedConnection] canShowInteractionForEvent:@"canShow"], @"If invocation is valid, it will be shown for the next targeted event.");
//
//	XCTAssertFalse([willNotShow criteriaAreMet], @"Invocation should not be valid.");
//	XCTAssertFalse([[Apptentive sharedConnection] canShowInteractionForEvent:@"cannotShow"], @"If invocation is not valid, it will not be shown for the next targeted event.");
//}

@end
