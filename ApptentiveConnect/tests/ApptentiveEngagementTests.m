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
#import "ApptentiveBackend+Engagement.h"
#import "Apptentive+Debugging.h"
#import "ApptentiveSession.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveBackend.h"


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
	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-5 * 60 * 60 * 24), @"$after": @(-7 * 60 * 60 * 24)} };

	ApptentiveSession *session = [[ApptentiveSession alloc] initWithAPIKey:@"foo"];

	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[session.appRelease setValue:@NO forKey:@"updateVersion"];
	[session.appRelease setValue:@NO forKey:@"updateBuild"];

	[session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForSession:session], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(6 * 60 * 60 * 24)},
		@"time_at_install/cf_bundle_short_version_string": @{@"$before": @(6 * 60 * 60 * 24)} };

	ApptentiveSession *session = [[ApptentiveSession alloc] initWithAPIKey:@"foo"];

	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[session.appRelease setValue:@NO forKey:@"updateVersion"];
	[session.appRelease setValue:@NO forKey:@"updateBuild"];

	[session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForSession:session], @"All keys are known, thus the criteria is met.");

	invocation.criteria = @{ @"time_since_install/total": @6,
		@"unknown_key": @"criteria_should_not_be_met" };
	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");

	invocation.criteria = @{ @6: @"this is weird" };
	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];

	invocation.criteria = nil;
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Dictionary with nil criteria should evaluate to False.");

	invocation.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Dictionary with Null criteria should evaluate to False.");

	invocation.criteria = @{};
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Empty criteria dictionary with no keys should evaluate to True.");

	invocation.criteria = @{ @"": @6 };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];

	ApptentiveSession *session = [[ApptentiveSession alloc] initWithAPIKey:@"foo"];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-6 * dayTimeInterval)} };
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForSession:session], @"Install date");
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-5 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Install date");

	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-5 * dayTimeInterval), @"$after": @(-7 * dayTimeInterval)} };
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForSession:session], @"Install date");
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-4.999 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Install date");
	[session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Install date");
}

- (void)testInteractionCriteriaDebug {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveSession *session = [[ApptentiveSession alloc] initWithAPIKey:@"foo"];

// Debug default to false
#if APPTENTIVE_DEBUG
	invocation.criteria = @{ @"application/debug": @YES };
#else
	invocation.criteria = @{ @"application/debug": @NO };
#endif

	XCTAssertTrue([invocation criteriaAreMetForSession:session], @"Debug boolean");

#if APPTENTIVE_DEBUG
	invocation.criteria = @{ @"application/debug": @NO };
#else
	invocation.criteria = @{ @"application/debug": @YES };
#endif

	XCTAssertFalse([invocation criteriaAreMetForSession:session], @"Debug boolean");
}

- (void)testInteractionCriteriaVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.2.8"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Version number");
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v1.2.8"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/version": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"application/version not a valid key");

	invocation.criteria = @{ @"application/version_code": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"application/version not a valid key");
}

- (void)testInteractionCriteriaBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Build number");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v39"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Build number must not have a 'v' in front!");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"3.0"] };
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Build number");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	invocation.criteria = @{ @"application/build": [Apptentive versionObjectWithVersion:@"3.0.0"] };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"application/build not a valid key");
}

- (void)testInteractionCriteriaSDK {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	invocation.criteria = @{ @"sdk/version": [Apptentive versionObjectWithVersion:@"1.4.2"] };
	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4.2"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"SDK Version should be 1.4.2");

	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"SDK Version isn't 1.4");

	[usageData.session.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.5.0"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"SDK Version isn't 1.5.0");

	invocation.criteria = @{ @"sdk/version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaCurrentTime {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	invocation.criteria = @{ @"current_time": @{@"$exists": @YES} };
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.session.currentTime timeIntervalSince1970];
	XCTAssertTrue(timestamp < (currentTimestamp + 0.5) && timestamp > (currentTimestamp - 0.5), @"Current time not a believable value.");

	invocation.criteria = @{ @"current_time": @{@"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-5]]} };
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$lt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:0.5]], @"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-0.5]]} };
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$gt": @"1183135260"} };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail because of type but not crash.");

	invocation.criteria = @{ @"current_time": @"1397598109" };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");
}

- (void)testCodePointInvokesVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	[usageData.session.engagement warmCodePoint:@"app.launch"];
	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"This version has been invoked 1 time.");
	[usageData.session.engagement resetBuild];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Reset build should not affect version");

	[usageData.session.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Codepoint version invokes.");
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Codepoint version invokes.");

	// "version" has been replaced with "cf_bundle_short_version_string"
	invocation.criteria = @{ @"interactions/big.win/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");
}

- (void)testCodePointInvokesBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	[usageData.session.engagement warmCodePoint:@"app.launch"];
	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_version": @1 };
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"This build has been invoked 1 time.");
	[usageData.session.engagement resetVersion];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Reset version should not affect version");

	[usageData.session.engagement resetBuild];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Codepoint build invokes.");
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Codepoint build invokes.");

	// "build" has been replaced with "cf_bundle_version"
	invocation.criteria = @{ @"interactions/big.win/invokes/build": @1 };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");
}

- (void)testInteractionInvokesVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	[usageData.session.engagement warmInteraction:@"526fe2836dd8bf546a00000b"];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @(1) };
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"This version has been invoked 1 time.");
	[usageData.session.engagement resetBuild];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Reset build should not affect version");

	[usageData.session.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Interaction version invokes.");
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Interaction version invokes.");

	// "version" has been replaced with "cf_bundle_short_version_string"
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");
}

- (void)testInteractionInvokesBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	[usageData.session.engagement warmInteraction:@"526fe2836dd8bf546a00000b"];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @(1) };
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"This version has been invoked 1 time.");
	[usageData.session.engagement resetVersion];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Reset build should not affect version");

	[usageData.session.engagement resetBuild];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Interaction build invokes.");
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	[usageData.session.engagement engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Interaction build invokes.");

	// "build" has been replaced with "cf_bundle_version"
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @1 };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");
}

- (void)testUpgradeMessageCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1,
		@"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.0"],
		@"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
	[usageData.session.engagement warmCodePoint:@"app.launch"];
	[usageData.session.engagement engageCodePoint:@"app.launch"];

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.3.0"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message without build number.");
	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");

	[usageData.session.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.3.1"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.1"],
		@"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$gte": @1} };

	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.1"],
		@"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$lte": @3} };
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");
	[usageData.session.engagement engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test Upgrade Message.");

	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @[@1],
		@"application_version": @"1.3.1",
		@"application_build": @"39" };

	[Apptentive.shared.backend.session.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");
}

- (void)testIsUpdateVersionsAndBuilds {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithSession:[[ApptentiveSession alloc] initWithAPIKey:@"foo"]];

	//Version
	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
	[usageData.session.appRelease setValue:@YES forKey:@"updateVersion"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
	[usageData.session.appRelease setValue:@NO forKey:@"updateVersion"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
	[usageData.session.appRelease setValue:@YES forKey:@"updateVersion"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	//Build
	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
	[usageData.session.appRelease setValue:@YES forKey:@"updateBuild"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
	[usageData.session.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertTrue([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
	[usageData.session.appRelease setValue:@YES forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Test isUpdate");


	invocation.criteria = @{ @"is_update/cf_bundle_version": @[[NSNull null]] };
	[usageData.session.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");
	invocation.criteria = @{ @"is_update/cf_bundle_version": @{@"$gt": @"lajd;fl ajsd;flj"} };
	[usageData.session.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid types.");

	[usageData.session.appRelease setValue:@NO forKey:@"updateVersion"];
	[usageData.session.appRelease setValue:@NO forKey:@"updateBuild"];
	invocation.criteria = @{ @"is_update/version_code": @NO };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");

	invocation.criteria = @{ @"is_update/version": @NO };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");

	invocation.criteria = @{ @"is_update/build": @NO };
	XCTAssertFalse([invocation criteriaAreMetForSession:usageData.session], @"Should fail with invalid key.");
}

- (void)testEnjoymentDialogCriteria {
	[Apptentive sharedConnection].APIKey = @"bogus_api_key"; // trigger creation of engagement backend
	sleep(1);

	Apptentive.shared.localInteractionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testInteractions" withExtension:@"json"];

	[Apptentive.shared.backend.session.engagement warmCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];

	[Apptentive.shared.backend.session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-863999] forKey:@"timeAtInstallTotal"];

	[Apptentive.shared.backend.session.engagement warmCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];

	XCTAssertFalse([Apptentive.shared canShowInteractionForEvent:@"testRatingFlow"], @"The OR clauses are failing.");

	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#init"];

	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];
	[Apptentive.shared.backend.session.engagement engageCodePoint:@"local#app#testRatingFlow"];

	XCTAssertTrue([Apptentive.shared canShowInteractionForEvent:@"testRatingFlow"], @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");

	[Apptentive.shared.backend.session.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-864001] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([Apptentive.shared canShowInteractionForEvent:@"testRatingFlow"], @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");

	[Apptentive.shared.backend.session.engagement warmInteraction:@"533ed97a7724c5457e00003f"];
	[Apptentive.shared.backend.session.engagement engageInteraction:@"533ed97a7724c5457e00003f"];
	XCTAssertFalse([Apptentive.shared canShowInteractionForEvent:@"testRatingFlow"], @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");
}

- (void)testCanShowInteractionForEvent {
	[Apptentive sharedConnection].APIKey = @"bogus_api_key"; // trigger creation of engagement backend
	sleep(1);

	Apptentive.shared.localInteractionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testInteractions" withExtension:@"json"];

	XCTAssertTrue([[Apptentive sharedConnection] canShowInteractionForEvent:@"canShow"], @"If invocation is valid, it will be shown for the next targeted event.");
	XCTAssertFalse([[Apptentive sharedConnection] canShowInteractionForEvent:@"cannotShow"], @"If invocation is not valid, it will not be shown for the next targeted event.");
}

@end
