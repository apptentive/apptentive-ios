//
//  ApptentiveEngagementTests.m
//  Apptentive
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "Apptentive+Debugging.h"
#import "Apptentive.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveConversation.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveMessageManager.h"
#import "ApptentiveSDK.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import <XCTest/XCTest.h>
#import "ApptentiveDispatchQueue.h"


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

- (void)setUp {
	[super setUp];

	NSString *path = [[[ApptentiveUtilities applicationSupportPath] stringByAppendingPathComponent:@"com.apptentive.feedback"] stringByAppendingPathComponent:@"conversation-v1.meta"];

	[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

- (void)testEventLabelsContainingCodePointSeparatorCharacters {
	//Escape "%", "/", and "#".

	NSString *i, *o;
	i = @"testEventLabelSeparators";
	o = @"testEventLabelSeparators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event#Label#Separators";
	o = @"test%23Event%23Label%23Separators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test/Event/Label/Separators";
	o = @"test%2FEvent%2FLabel%2FSeparators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%Event/Label#Separators";
	o = @"test%25Event%2FLabel%23Separators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#Event/Label%Separators";
	o = @"test%23Event%2FLabel%25Separators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test###Event///Label%%%Separators";
	o = @"test%23%23%23Event%2F%2F%2FLabel%25%25%25Separators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test#%///#%//%%/#Event_!@#$%^&*(){}Label1234567890[]`~Separators";
	o = @"test%23%25%2F%2F%2F%23%25%2F%2F%25%25%2F%23Event_!@%23$%25^&*(){}Label1234567890[]`~Separators";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");

	i = @"test%/#";
	o = @"test%25%2F%23";
	XCTAssertTrue([[ApptentiveBackend stringByEscapingCodePointSeparatorCharactersInString:i] isEqualToString:o], @"Test escaping code point separator characters from event labels.");
}

- (void)testInteractionCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-5 * 60 * 60 * 24), @"$after": @(-7 * 60 * 60 * 24)} };

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[conversation.appRelease setValue:@NO forKey:@"updateVersion"];
	[conversation.appRelease setValue:@NO forKey:@"updateBuild"];

	[conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForConversation:conversation], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(6 * 60 * 60 * 24)},
		@"time_at_install/cf_bundle_short_version_string": @{@"$before": @(6 * 60 * 60 * 24)} };

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallTotal"];
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * 60 * 60 * 24] forKey:@"timeAtInstallVersion"];
	[conversation.appRelease setValue:@NO forKey:@"updateVersion"];
	[conversation.appRelease setValue:@NO forKey:@"updateBuild"];

	[conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.8.9"] forKey:@"version"];
	[conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForConversation:conversation], @"All keys are known, thus the criteria is met.");

	invocation.criteria = @{ @"time_since_install/total": @6,
		@"unknown_key": @"criteria_should_not_be_met" };
	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");

	invocation.criteria = @{ @6: @"this is weird" };
	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] init];

	invocation.criteria = nil;
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Dictionary with nil criteria should evaluate to False.");

	invocation.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Dictionary with Null criteria should evaluate to False.");

	invocation.criteria = @{};
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Empty criteria dictionary with no keys should evaluate to True.");

	invocation.criteria = @{ @"": @6 };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

	NSTimeInterval dayTimeInterval = 60 * 60 * 24;

	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-6 * dayTimeInterval)} };
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:conversation], @"Install date");
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-5 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Install date");

	invocation.criteria = @{ @"time_at_install/total": @{@"$before": @(-5 * dayTimeInterval), @"$after": @(-7 * dayTimeInterval)} };
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-6 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:conversation], @"Install date");
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-4.999 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Install date");
	[conversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-7 * dayTimeInterval] forKey:@"timeAtInstallTotal"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Install date");
}

- (void)testInteractionCriteriaDebug {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

// Debug default to false
#if APPTENTIVE_DEBUG
	invocation.criteria = @{ @"application/debug": @YES };
#else
	invocation.criteria = @{ @"application/debug": @NO };
#endif

	XCTAssertTrue([invocation criteriaAreMetForConversation:conversation], @"Debug boolean");

#if APPTENTIVE_DEBUG
	invocation.criteria = @{ @"application/debug": @NO };
#else
	invocation.criteria = @{ @"application/debug": @YES };
#endif

	XCTAssertFalse([invocation criteriaAreMetForConversation:conversation], @"Debug boolean");
}

- (void)testInteractionCriteriaVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.2.8"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Version number");
	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v1.2.8"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Version number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/version": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"application/version not a valid key");

	invocation.criteria = @{ @"application/version_code": [Apptentive versionObjectWithVersion:@"1.2.8"] };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"application/version not a valid key");
}

- (void)testInteractionCriteriaBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];

	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Build number");

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v39"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Build number must not have a 'v' in front!");

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"3.0"] };
	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Build number");

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"v3.0"] forKey:@"build"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Build number must not have a 'v' in front!");

	invocation.criteria = @{ @"application/cf_bundle_version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"3.0"] forKey:@"build"];
	invocation.criteria = @{ @"application/build": [Apptentive versionObjectWithVersion:@"3.0.0"] };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"application/build not a valid key");
}

- (void)testInteractionCriteriaSDK {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	invocation.criteria = @{ @"sdk/version": [Apptentive versionObjectWithVersion:@"1.4.2"] };
	[usageData.conversation.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4.2"] forKey:@"version"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"SDK Version should be 1.4.2");

	[usageData.conversation.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.4"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"SDK Version isn't 1.4");

	[usageData.conversation.SDK setValue:[[ApptentiveVersion alloc] initWithString:@"1.5.0"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"SDK Version isn't 1.5.0");

	invocation.criteria = @{ @"sdk/version": @{@"$contains": @3.0} };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaCurrentTime {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	invocation.criteria = @{ @"current_time": @{@"$exists": @YES} };
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.conversation.currentTime timeIntervalSince1970];
	XCTAssertTrue(timestamp < (currentTimestamp + 0.5) && timestamp > (currentTimestamp - 0.5), @"Current time not a believable value.");

	invocation.criteria = @{ @"current_time": @{@"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-5]]} };
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$lt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:0.5]], @"$gt": [Apptentive timestampObjectWithDate:[NSDate dateWithTimeIntervalSinceNow:-0.5]]} };
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Current time criteria not met.");

	invocation.criteria = @{ @"current_time": @{@"$gt": @"1183135260"} };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail because of type but not crash.");

	invocation.criteria = @{ @"current_time": @"1397598109" };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");
}

- (void)testCodePointInvokesVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	[usageData.conversation warmCodePoint:@"app.launch"];
	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1 };
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"This version has been invoked 1 time.");
	[usageData.conversation.engagement resetBuild];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Reset build should not affect version");

	[usageData.conversation.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Codepoint version invokes.");
	[usageData.conversation engageCodePoint:@"app.launch"];
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Codepoint version invokes.");

	// "version" has been replaced with "cf_bundle_short_version_string"
	invocation.criteria = @{ @"interactions/big.win/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");
}

- (void)testCodePointInvokesBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	[usageData.conversation warmCodePoint:@"app.launch"];
	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_version": @1 };
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"This build has been invoked 1 time.");
	[usageData.conversation.engagement resetVersion];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Reset version should not affect version");

	[usageData.conversation.engagement resetBuild];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Codepoint build invokes.");
	[usageData.conversation engageCodePoint:@"app.launch"];
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Codepoint build invokes.");

	// "build" has been replaced with "cf_bundle_version"
	invocation.criteria = @{ @"interactions/big.win/invokes/build": @1 };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");
}

- (void)testInteractionInvokesVersion {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	[usageData.conversation warmInteraction:@"526fe2836dd8bf546a00000b"];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_short_version_string": @(1) };
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"This version has been invoked 1 time.");
	[usageData.conversation.engagement resetBuild];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Reset build should not affect version");

	[usageData.conversation.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Interaction version invokes.");
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Interaction version invokes.");

	// "version" has been replaced with "cf_bundle_short_version_string"
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/version": @1 };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");
}

- (void)testInteractionInvokesBuild {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	[usageData.conversation warmInteraction:@"526fe2836dd8bf546a00000b"];
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/cf_bundle_version": @(1) };
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"This version has been invoked 1 time.");
	[usageData.conversation.engagement resetVersion];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Reset build should not affect version");

	[usageData.conversation.engagement resetBuild];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Interaction build invokes.");
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	[usageData.conversation engageInteraction:@"526fe2836dd8bf546a00000b"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Interaction build invokes.");

	// "build" has been replaced with "cf_bundle_version"
	invocation.criteria = @{ @"interactions/526fe2836dd8bf546a00000b/invokes/build": @1 };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");
}

- (void)testUpgradeMessageCriteria {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @1,
		@"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.0"],
		@"application/cf_bundle_version": [Apptentive versionObjectWithVersion:@"39"] };
	[usageData.conversation warmCodePoint:@"app.launch"];
	[usageData.conversation engageCodePoint:@"app.launch"];

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.3.0"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message without build number.");
	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"39"] forKey:@"build"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");

	[usageData.conversation.appRelease setValue:[[ApptentiveVersion alloc] initWithString:@"1.3.1"] forKey:@"version"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.1"],
		@"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$gte": @1} };

	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");

	invocation.criteria = @{ @"application/cf_bundle_short_version_string": [Apptentive versionObjectWithVersion:@"1.3.1"],
		@"code_point/app.launch/invokes/cf_bundle_short_version_string": @{@"$lte": @3} };
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");
	[usageData.conversation engageCodePoint:@"app.launch"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test Upgrade Message.");

	invocation.criteria = @{ @"code_point/app.launch/invokes/cf_bundle_short_version_string": @[@1],
		@"application_version": @"1.3.1",
		@"application_build": @"39" };

	[Apptentive.shared.backend.conversationManager.activeConversation.engagement resetVersion];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");
}

- (void)testIsUpdateVersionsAndBuilds {
	ApptentiveInteractionInvocation *invocation = [[ApptentiveInteractionInvocation alloc] init];
	ApptentiveInteractionUsageData *usageData = [[ApptentiveInteractionUsageData alloc] initWithConversation:[[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous]];

	//Version
	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
	[usageData.conversation.appRelease setValue:@YES forKey:@"updateVersion"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
	[usageData.conversation.appRelease setValue:@NO forKey:@"updateVersion"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @YES };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_short_version_string": @NO };
	[usageData.conversation.appRelease setValue:@YES forKey:@"updateVersion"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	//Build
	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
	[usageData.conversation.appRelease setValue:@YES forKey:@"updateBuild"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
	[usageData.conversation.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertTrue([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @YES };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");

	invocation.criteria = @{ @"is_update/cf_bundle_version": @NO };
	[usageData.conversation.appRelease setValue:@YES forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Test isUpdate");


	invocation.criteria = @{ @"is_update/cf_bundle_version": @[[NSNull null]] };
	[usageData.conversation.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");
	invocation.criteria = @{ @"is_update/cf_bundle_version": @{@"$gt": @"lajd;fl ajsd;flj"} };
	[usageData.conversation.appRelease setValue:@NO forKey:@"updateBuild"];
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid types.");

	[usageData.conversation.appRelease setValue:@NO forKey:@"updateVersion"];
	[usageData.conversation.appRelease setValue:@NO forKey:@"updateBuild"];
	invocation.criteria = @{ @"is_update/version_code": @NO };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");

	invocation.criteria = @{ @"is_update/version": @NO };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");

	invocation.criteria = @{ @"is_update/build": @NO };
	XCTAssertFalse([invocation criteriaAreMetForConversation:usageData.conversation], @"Should fail with invalid key.");
}

- (void)testEnjoymentDialogCriteria {
	ApptentiveConfiguration *configuration = [ApptentiveConfiguration configurationWithApptentiveKey:@"app-key" apptentiveSignature:@"app-signature"];
	[Apptentive registerWithConfiguration:configuration];

	Apptentive.shared.logLevel = ApptentiveLogLevelVerbose;

	XCTestExpectation *expectation = [self expectationWithDescription:@"Backend stood up"];

	[Apptentive.shared.backend.operationQueue dispatchAsync:^{
		Apptentive.shared.localInteractionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testInteractions" withExtension:@"json"];

		[Apptentive.shared.backend.conversationManager.activeConversation warmCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];

		[Apptentive.shared.backend.conversationManager.activeConversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-863999] forKey:@"timeAtInstallTotal"];

		[Apptentive.shared.backend.conversationManager.activeConversation warmCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
		[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];

		[Apptentive.shared.backend.conversationManager.activeConversation warmInteraction:@"533ed97a7724c5457e00003f"];

		[Apptentive.shared queryCanShowInteractionForEvent:@"testRatingFlow" completion:^(BOOL canShowInteraction) {
			XCTAssertFalse(canShowInteraction, @"The OR clauses are failing.");

			[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];
			[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#init"];

			[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];
			[Apptentive.shared.backend.conversationManager.activeConversation engageCodePoint:@"local#app#testRatingFlow"];

			[Apptentive.shared queryCanShowInteractionForEvent:@"testRatingFlow" completion:^(BOOL canShowInteraction) {
				XCTAssertTrue(canShowInteraction, @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");

				[Apptentive.shared.backend.conversationManager.activeConversation.appRelease setValue:[NSDate dateWithTimeIntervalSinceNow:-864001] forKey:@"timeAtInstallTotal"];
				[Apptentive.shared queryCanShowInteractionForEvent:@"testRatingFlow" completion:^(BOOL canShowInteraction) {
					XCTAssertTrue(canShowInteraction, @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");

					[Apptentive.shared.backend.conversationManager.activeConversation engageInteraction:@"533ed97a7724c5457e00003f"];
					[Apptentive.shared queryCanShowInteractionForEvent:@"testRatingFlow" completion:^(BOOL canShowInteraction) {
						XCTAssertFalse(canShowInteraction, @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");

						[expectation fulfill];
					}];
				}];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testCanShowInteractionForEvent {
	// TODO: create synchronous backend initializer
	ApptentiveConfiguration *configuration = [ApptentiveConfiguration configurationWithApptentiveKey:@"app-key" apptentiveSignature:@"app-signature"];
	[Apptentive registerWithConfiguration:configuration]; // trigger creation of engagement backend

	XCTestExpectation *expectation = [self expectationWithDescription:@"Backend stood up"];

	[Apptentive.shared.backend.operationQueue dispatchAsync:^{
		[Apptentive.shared.backend.conversationManager.activeConversation setValue:@"abc123" forKey:@"token"];
		[Apptentive.shared.backend.conversationManager.activeConversation setValue:@"abc123" forKey:@"identifier"];

	  [Apptentive.shared.backend.conversationManager createMessageManagerForConversation:Apptentive.shared.backend.conversationManager.activeConversation];
	  Apptentive.shared.localInteractionsURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"testInteractions" withExtension:@"json"];

		[Apptentive.shared queryCanShowInteractionForEvent:@"canShow" completion:^(BOOL canShowInteraction) {
			XCTAssertTrue(canShowInteraction, @"If invocation is valid, it will be shown for the next targeted event.");

			[Apptentive.shared queryCanShowInteractionForEvent:@"cannotShow" completion:^(BOOL canShowInteraction) {
				XCTAssertFalse(canShowInteraction, @"If invocation is not valid, it will not be shown for the next targeted event.");

				[expectation fulfill];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
