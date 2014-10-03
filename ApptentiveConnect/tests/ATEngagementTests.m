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
#import "ATInteractionUsageData.h"
#import "ATEngagementBackend.h"
#import "ATEngagementManifestParser.h"

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
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"time_since_install/total": @{@"$gt": @(5 * 60 * 60 * 24), @"$lt": @(7 * 60 * 60 * 24)}};
	
	ATInteractionUsageData *usageData = [ATInteractionUsageData usageDataForInteraction:interaction];
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
	
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testUnknownKeyInCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"time_since_install/total": @(6 * 60 * 60 * 24), @"time_since_install/version": @(6 * 60 * 60 * 24)};
	
	ATInteractionUsageData *usageData = [ATInteractionUsageData usageDataForInteraction:interaction];
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
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"All keys are known, thus the criteria is met.");
	
	interaction.criteria = @{@"time_since_install/total": @6, @"unknown_key": @"criteria_should_not_be_met"};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
	
	interaction.criteria = @{@6:@"this is weird"};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Criteria should not be met if the criteria includes a key that the client does not recognize.");
}

- (void)testEmptyCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = nil;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Dictionary with nil criteria should evaluate to False.");
	
	interaction.criteria = @{[NSNull null]: [NSNull null]};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Dictionary with Null criteria should evaluate to False.");

	interaction.criteria = @{};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Empty criteria dictionary with no keys should evaluate to True.");
	
	interaction.criteria = @{@"": @6};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Criteria with a key that is an empty string should fail (if usage data does not match).");
}

- (void)testInteractionCriteriaDaysSnceInstall {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	NSTimeInterval dayTimeInterval = 60 * 60 * 24;
	
	interaction.criteria = @{@"time_since_install/total": @(6 * dayTimeInterval)};
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(7 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"time_since_install/total": @{@"$gt": @(5 * dayTimeInterval), @"$lt": @(7 * dayTimeInterval)}};
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(7 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"time_since_install/total": @{@"$lte": @(5 * dayTimeInterval), @"$gt": @(3 * dayTimeInterval)}};
	usageData.timeSinceInstallTotal = @(3 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(4 * dayTimeInterval);
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(5 * dayTimeInterval);
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.timeSinceInstallTotal = @(6 * dayTimeInterval);
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	
	interaction.criteria = @{@"time_since_install/total": @{@"$lte": @"5", @"$gt": @"3"}};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"application_version": @"1.2.8"};
	usageData.applicationVersion = @"1.2.8";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	interaction.criteria = @{@"application_version": @"v3.0"};
	usageData.applicationVersion = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"app_release/version": @"1.2.8"};
	usageData.applicationVersion = @"1.2.8";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	interaction.criteria = @{@"app_release/version": @"v3.0"};
	usageData.applicationVersion = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	
	interaction.criteria = @{@"app_release/version": @{@"$gt": @3.0}};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaBuild {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"application_build": @"39"};
	usageData.applicationBuild = @"39";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"v39";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
	
	interaction.criteria = @{@"application_build": @"v3.0"};
	usageData.applicationBuild = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
	
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"app_release/build": @"39"};
	usageData.applicationBuild = @"39";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"v39";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
	
	interaction.criteria = @{@"app_release/build": @"v3.0"};
	usageData.applicationBuild = @"v3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Build number");
	
	usageData.applicationBuild = @"3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Build number must not have a 'v' in front!");
	
	
	interaction.criteria = @{@"app_release/build": @{@"$contains":@3.0}};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInteractionCriteriaSDK {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"sdk/version": kATConnectVersionString};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Default value should be current version.");
	
	interaction.criteria = @{@"sdk/version": @"1.4.2"};
	usageData.sdkVersion = @"1.4.2";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"SDK Version should be 1.4.2");
	
	usageData.sdkVersion = @"1.4";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.4");
	
	usageData.sdkVersion = @"1.5.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"SDK Version isn't 1.5.0");
	
	interaction.criteria = @{@"sdk/version": @{@"$contains":@3.0}};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
	
	interaction.criteria = @{@"sdk/distribution": @"CocoaPods-Source"};
	usageData.sdkDistribution = @"CocoaPods-Source";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"SDK Distribution should be CocoaPods-Source");
	
	interaction.criteria = @{@"sdk/distribution": @{@"$contains":@"CocoaPods"}};
	usageData.sdkDistribution = @"CocoaPods-Source";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"SDK Distribution should contain CocoaPods");
	
	interaction.criteria = @{@"sdk/distribution_version": @"foo"};
	usageData.sdkDistributionVersion = @"foo";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"SDK Distribution Version should match.");
}

- (void)testInteractionCriteriaCurrentTime {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"current_time": @{@"$exists": @YES}};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Must have default current time.");
	// Make sure it's actually a reasonable value…
	NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval timestamp = [usageData.currentTime doubleValue];
	XCTAssertTrue(timestamp < currentTimestamp && timestamp > (currentTimestamp - 5), @"Current time not a believable value.");
	
	interaction.criteria = @{@"current_time":@{@"$gt": @1397598108.63843}};
	usageData.currentTime = @1397598109;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");
	
	interaction.criteria = @{@"current_time":@{@"$lt": @1183135260, @"$gt": @465498000}};
	usageData.currentTime = @1183135259.5;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Current time criteria not met.");
	
	interaction.criteria = @{@"current_time":@{@"$gt": @"1183135260"}};
	usageData.currentTime = @1397598109;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because of type but not crash.");
	
	interaction.criteria = @{@"current_time": @"1397598109"};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testCodePointInvokesVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version": @1};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"This version has been invoked 1 time.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @0};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	
	interaction.criteria = @{@"code_point/big.win/invokes/version": @7};
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @7};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @1};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @19};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	interaction.criteria = @{@"code_point/big.win/invokes/version": @{@"$gte": @5, @"$lte": @5}};
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @5};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @3};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @19};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	
	
	interaction.criteria = @{@"code_point/big.win/invokes/version": @{@"$gte": @"5", @"$lte": @"5"}};
	usageData.codePointInvokesVersion = @{@"code_point/big.win/invokes/version": @5};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testUpgradeMessageCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version": @1,
							 @"application_version": @"1.3.0",
							 @"application_build": @"39"};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message without build number.");
	usageData.applicationBuild = @"39";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.1";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	interaction.criteria = @{@"application_version": @"1.3.0",
							 @"code_point/app.launch/invokes/version": @{@"$gte": @1}};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @2};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @0};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	
	interaction.criteria = @{@"application_version": @"1.3.0",
							 @"code_point/app.launch/invokes/version": @{@"$lte": @4}};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @4};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @5};
	usageData.applicationVersion = @"1.3.0";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version": @[@1],
							 @"application_version": @"1.3.0",
							 @"application_build": @"39"};
	usageData.codePointInvokesVersion = @{@"code_point/app.launch/invokes/version": @1};
	usageData.applicationVersion = @"1.3.0";
	usageData.applicationBuild = @"39";
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testNewUpgradeMessageCriteria {
	NSString *jsonString = @"{\"interactions\":{\"app.launch\":[{\"priority\":1,\"criteria\":{\"interactions/52fadf097724c5c09f000012/invokes/total\":0,\"application_version\":\"999\",\"time_since_install/version\":{\"$lt\":604800},\"is_update/version\":true},\"id\":\"52fadf097724c5c09f000012\",\"type\":\"UpgradeMessage\",\"configuration\":{\"show_app_icon\":true,\"show_powered_by\":true,\"body\":\"<html><head><style>\\nbody {\\n  font-family: \\\"Helvetica Neue\\\", Helvetica;\\n  color: #4d4d4d;\\n  font-size: .875em;\\n  line-height: 1.36em;\\n  -webkit-text-size-adjust:none;\\n}\\n\\nh1, h2, h3, h4, h5, h6 {\\n  color: #000000;\\n  line-height: 1.25em;\\n  text-align: center;\\n}\\n\\nh1 {font-size: 22px;}\\nh2 {font-size: 18px;}\\nh3 {font-size: 16px;}\\nh4 {font-size: 14px;}\\nh5, h6 {font-size: 12px;}\\nh6 {font-weight: normal;}\\n\\nblockquote {\\n  margin: 1em 1.75em;\\n  font-style: italic;\\n}\\n\\nul, ol {\\n  padding-left: 1.75em;\\n}\\n\\ntable {\\n  border-collapse: collapse;\\n  border-spacing: 0;\\n  empty-cells: show;\\n}\\n\\ntable caption {\\n  padding: 1em 0;\\n  text-align: center;\\n}\\n\\ntable td,\\ntable th {\\n  border-left: 1px solid #cbcbcb;\\n  border-width: 0 0 0 1px;\\n  font-size: inherit;\\n  margin: 0;\\n  padding: .25em .5em;\\n\\n}\\ntable td:first-child,\\ntable th:first-child {\\n  border-left-width: 0;\\n}\\ntable th:first-child {\\n  border-radius: 4px 0 0 4px;\\n}\\ntable th:last-child {\\n  border-radius: 0 4px 4px 0;\\n}\\n\\ntable thead {\\n  background: #E5E5E5;\\n  color: #000;\\n  text-align: left;\\n  vertical-align: bottom;\\n}\\n\\ntable td {\\n  background-color: transparent;\\n  border-bottom: 1px solid #E5E5E5;\\n}\\n</style></head><body><p>This is a test upgrade message.</p></body></html>\"}}]}}";
	
	/*
	criteria =     {
        "application_version" = 999;
        "interactions/52fadf097724c5c09f000012/invokes/total" = 0;
        "is_update/version" = 1;
        "time_since_install/version" =         {
            "$lt" = 604800;
        };
    };
	*/
	
	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *interactions = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
	
	NSDictionary *codePoints = [interactions objectForKey:@"interactions"];
	NSDictionary *appLaunchInteraction = [[codePoints objectForKey:@"app.launch"] objectAtIndex:0];
	
	ATInteraction *upgradeMessageInteraction = [ATInteraction interactionWithJSONDictionary:appLaunchInteraction];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{@"interactions/52fadf097724c5c09f000012/invokes/total": @0};
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertTrue([upgradeMessageInteraction criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria met!");
	
	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"998";
	usageData.interactionInvokesTotal = @{@"interactions/52fadf097724c5c09f000012/invokes/total": @0};
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteraction criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");
	
	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{@"interactions/52fadf097724c5c09f000012/invokes/total": @0};
	usageData.isUpdateVersion = @NO;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteraction criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");
	
	usageData = [[ATInteractionUsageData alloc] init];
	usageData.applicationVersion = @"999";
	usageData.interactionInvokesTotal = @{@"interactions/52fadf097724c5c09f000012/invokes/total": @1};
	usageData.isUpdateVersion = @YES;
	usageData.timeSinceInstallVersion = @(2 * 24 * 60 * 60);
	XCTAssertFalse([upgradeMessageInteraction criteriaAreMetForUsageData:usageData], @"Upgrade Message criteria not met!");
}

- (void)testComplexCriteria {
	NSString *jsonString = @"{\"interactions\":{\"app.launch\":[{\"id\":\"526fe2836dd8bf546a00000c\",\"priority\":2,\"criteria\":{\"time_since_install/version\":{\"$lt\":259200},\"code_point/app.launch/invokes/total\":2,\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"big.win\":[{\"id\":\"526fe2836dd8bf546a00000d\",\"priority\":1,\"criteria\":{},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"or_clause\":[{\"id\":\"526fe2836dd8bf546a00000e\",\"priority\":1,\"criteria\":{\"$or\":[{\"time_since_install/version\":{\"$lt\":259200}},{\"code_point/app.launch/invokes/total\":2},{\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0}]},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}],\"complext_criteria\":[{\"id\":\"526fe2836dd8bf546a00000f\",\"priority\":1,\"criteria\":{\"$or\":[{\"time_since_install/version\":{\"$lt\":259200}},{\"$and\":[{\"code_point/app.launch/invokes/total\":2},{\"interactions/526fe2836dd8bf546a00000b/invokes/version\":0},{\"$or\":[{\"code_point/small.win/invokes/total\":2},{\"code_point/big.win/invokes/total\":2}]}]}]},\"type\":\"RatingDialog\",\"version\":null,\"active\":true,\"configuration\":{\"active\":true,\"question_text\":\"Do you love Jelly Bean GO SMS Pro?\"}}]}}";

	/*
	criteria = {
		"$or" = ({
			"days_since_upgrade" = {
				"$lt" = 3;
			};
		},
		{
			"$and" = ({
				"code_point/app.launch/invokes/total" = 2;
			},
			{
				"interactions/526fe2836dd8bf546a00000b/invokes/version" = 0;
			},
			{
				"$or" = ({
					"code_point/small.win/invokes/total" = 2;
				},
				{
					"code_point/big.win/invokes/total" = 2;
				});
			});
		});
	};
	*/
	

	NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *interactions = [NSJSONSerialization JSONObjectWithData:jsonData
																 options:NSJSONReadingAllowFragments
																   error:nil];
	
	NSDictionary *codePoints = [interactions objectForKey:@"interactions"];
	NSDictionary *complexInteractionDictionary = [[codePoints objectForKey:@"complext_criteria"] objectAtIndex:0];
	
	ATInteraction *complexInteraction = [ATInteraction interactionWithJSONDictionary:complexInteractionDictionary];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	NSTimeInterval dayTimeInterval = 60 * 60 * 24;
	
	usageData.timeSinceInstallVersion = @(2 * dayTimeInterval);
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"2 satisfies the inital OR clause; passes regardless of the next condition.");
	usageData.timeSinceInstallVersion = @(0 * dayTimeInterval);
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"0 satisfies the inital OR clause; passes regardless of the next condition.");
	
	usageData.timeSinceInstallVersion = @(3 * dayTimeInterval);
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @8};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"3 fails the initial OR clause. 8 fails the other clause.");

	usageData.timeSinceInstallVersion = @(3 * dayTimeInterval);
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @0};
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @0,
										@"code_point/big.win/invokes/total": @2};
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @2,
										@"code_point/big.win/invokes/total": @19};
	XCTAssertTrue([complexInteraction criteriaAreMetForUsageData:usageData], @"complex");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @19,
										@"code_point/big.win/invokes/total": @19};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"Neither of the last two ORed code_point totals are right.");
	usageData.codePointInvokesTotal = @{@"code_point/app.launch/invokes/total": @2,
										@"code_point/small.win/invokes/total": @2,
										@"code_point/big.win/invokes/total": @1};
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @8};
	XCTAssertFalse([complexInteraction criteriaAreMetForUsageData:usageData], @"The middle case is incorrect.");
}

- (void)testTimeAgoCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @100,
							 @"interactions/big.win/invokes/time_ago": @1000};
	
	usageData.codePointInvokesTimeAgo = @{@"code_point/app.launch/invokes/time_ago": @100};
	usageData.interactionInvokesTimeAgo = @{@"interactions/big.win/invokes/time_ago": @1000};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500},
							 @"interactions/big.win/invokes/time_ago": @{@"$lte": @1000}};
	usageData.codePointInvokesTimeAgo = @{@"code_point/app.launch/invokes/time_ago": @800};
	usageData.interactionInvokesTimeAgo = @{@"interactions/big.win/invokes/time_ago": @100};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoCodePointCriteriaViaDatesInNSUserDefaults {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];

	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$lte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate distantPast]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate distantPast]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": [NSDate dateWithTimeIntervalSinceNow:-600]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$gte": @500}};
	usageData.codePointInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"app.launch": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501]} forKey:ATEngagementCodePointsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testTimeAgoInteractionCriteriaViaDatesInNSUserDefaults {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$lte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate distantPast]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo: distantPast -> now time interval > 500");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate distantPast]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": [NSDate dateWithTimeIntervalSinceNow:-600]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-400]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/time_ago": @{@"$gte": @500}};
	usageData.interactionInvokesTimeAgo = nil;
	[[NSUserDefaults standardUserDefaults] setObject:@{@"526fe2836dd8bf546a00000b": (NSDate *)[NSDate dateWithTimeIntervalSinceNow:-501]} forKey:ATEngagementInteractionsInvokesLastDateKey];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test timeAgo");
}

- (void)testIsUpdateVersionsAndBuilds {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	//Version
	interaction.criteria = @{@"is_update/version": @YES};
	usageData.isUpdateVersion = @YES;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/version": @NO};
	usageData.isUpdateVersion = @NO;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/version": @YES};
	usageData.isUpdateVersion = @NO;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/version": @NO};
	usageData.isUpdateVersion = @YES;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");

	//Build
	interaction.criteria = @{@"is_update/build": @YES};
	usageData.isUpdateBuild = @YES;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/build": @NO};
	usageData.isUpdateBuild = @NO;
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/build": @YES};
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	interaction.criteria = @{@"is_update/build": @NO};
	usageData.isUpdateBuild = @YES;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test isUpdate");
	
	
	interaction.criteria = @{@"is_update/build": @[[NSNull null]]};
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
	interaction.criteria = @{@"is_update/build": @{@"$gt":@"lajd;fl ajsd;flj"}};
	usageData.isUpdateBuild = @NO;
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail with invalid types.");
}

- (void)testInvokesVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6}};
	
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$gte": @6}};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Invokes version should default to 0 when not set.");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6}};
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @1};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Invokes version");

	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @{@"$lte": @6}};
	usageData.interactionInvokesVersion = @{@"interactions/526fe2836dd8bf546a00000b/invokes/version": @7};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Invokes version");
}

- (void)testInvokesBuild {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6}};
	
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$gte": @6}};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Invokes build should default to 0 when not set.");

	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6}};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	usageData.interactionInvokesBuild = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @1};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Invokes build");
	
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$lte": @6}};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	usageData.interactionInvokesBuild = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @7};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Invokes build");
}

- (void)testEnjoymentDialogCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"$or": @[@{@"code_point/local#app#init/invokes/version": @{@"$gte": @10}},
									   @{@"time_since_install/total": @{@"$gt": @864000}},
									   @{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt":@10}}
									   ],
							 @"interactions/533ed97a7724c5457e00003f/invokes/version": @0};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	
	
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	usageData.codePointInvokesVersion = @{@"code_point/local#app#init/invokes/version": @9};
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{@"code_point/local#app#testRatingFlow/invokes/total": @9};
	usageData.interactionInvokesVersion = @{@"interactions/533ed97a7724c5457e00003f/invokes/version": @0};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"The OR clauses are failing.");
	
	usageData.codePointInvokesVersion = @{@"code_point/local#app#init/invokes/version": @11};
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{@"code_point/local#app#testRatingFlow/invokes/total": @9};
	usageData.interactionInvokesVersion = @{@"interactions/533ed97a7724c5457e00003f/invokes/version": @0};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"One of the OR clauses is true. The other ANDed clause is also true. Should work.");
	
	usageData.codePointInvokesVersion = @{@"code_point/local#app#init/invokes/version": @11};
	usageData.timeSinceInstallTotal = @864001;
	usageData.codePointInvokesTotal = @{@"code_point/local#app#testRatingFlow/invokes/total": @11};
	usageData.interactionInvokesVersion = @{@"interactions/533ed97a7724c5457e00003f/invokes/version": @0};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"All of the OR clauses are true. The other ANDed clause is also true. Should work.");
	
	usageData.interactionInvokesVersion = @{@"interactions/533ed97a7724c5457e00003f/invokes/version": @1};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"All the OR clauses are true. The other ANDed clause is not true. Should fail.");
}

- (void)testNotInCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"$and": @[@{@"code_point/local#app#init/invokes/version": @{@"$not": @{@"$gte": @10}}},
									   @{@"time_since_install/total": @{@"$not": @{@"$gt": @864000}}},
									   @{@"code_point/local#app#testRatingFlow/invokes/total": @{@"$gt":@10}}
									   ],
							 @"interactions/533ed97a7724c5457e00003f/invokes/version": @0
							 };
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	usageData.codePointInvokesVersion = @{@"code_point/local#app#init/invokes/version": @9};
	usageData.timeSinceInstallTotal = @863999;
	usageData.codePointInvokesTotal = @{@"code_point/local#app#testRatingFlow/invokes/total": @9};
	usageData.interactionInvokesVersion = @{@"interactions/533ed97a7724c5457e00003f/invokes/version": @0};
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail due to invokes/version being 9.");
	
	usageData.codePointInvokesTotal = @{@"code_point/local#app#testRatingFlow/invokes/total": @11};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass due to invokes being 11.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @{@"$not": @{@"$gt": @6}}};
	usageData.interactionInvokesBuild = @{@"interactions/526fe2836dd8bf546a00000b/invokes/build": @1};
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because 6 is not > 1.");
}

- (void)testContainsCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$contains": @"a"}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because a is in 1.2.3a");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$contains": @"1.4"}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because 1.4 is not in 1.2.3a");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$contains": @"abc"}};
	usageData.applicationVersion = @"AbC";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Contains should be case insensitive.");
}

- (void)testStartsWithCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$starts_with": @"1.2."}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because 1.2.3a starts with 1.2.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$starts_with": @"1.4"}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because 1.2.3a doesn't start with 1.4");
	
	// Test directionality.
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$starts_with": @"abcd"}};
	usageData.applicationVersion = @"abc";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because abc doesn't start with abcd.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$starts_with": @"abc"}};
	usageData.applicationVersion = @"AbCdEF";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"starts_with should be case insensitive.");
}

- (void)testEndsWithCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$ends_with": @"a"}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because 1.2.3a ends with a");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$ends_with": @"1.4"}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because 1.2.3a doesn't end in 1.4");
	
	// Test directionality
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$ends_with": @"abcd"}};
	usageData.applicationVersion = @"bcd";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because bcd doesn't end with abcd.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$ends_with": @"DEF"}};
	usageData.applicationVersion = @"AbCdEf";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Ends with should be case insensitive.");
}

- (void)testExistsCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$exists": @YES}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because application_version exists.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$exists": @YES}};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because application_version doesn't exist.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_version": @{@"$exists": @NO}};
	usageData.applicationVersion = @"1.2.3a";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Should fail because application_version exists.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_build": @{@"$exists": @NO}};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because application_build doesn't exist.");
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"application_build": @{@"$exists": @YES}};
	usageData.applicationBuild = @"nil";
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because application_build exists.");
	
	
	interaction = [[ATInteraction alloc] init];
	usageData = [[ATInteractionUsageData alloc] init];
	interaction.criteria = @{@"code_point/app.launch/invokes/time_ago": @{@"$exists": @YES},
							 @"interactions/big.win/invokes/time_ago": @{@"$exists": @NO}};
	usageData.codePointInvokesTimeAgo = @{@"code_point/app.launch/invokes/time_ago": @800};
	usageData.interactionInvokesTimeAgo = @{};
	XCTAssertNotNil([interaction criteriaPredicate], @"Criteria should parse correctly.");
	XCTAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Should pass because invokes/time_ago exists.");
}

- (void)testInvalidJSON {
	NSString *json = @"";
	ATEngagementManifestParser *parser = [[ATEngagementManifestParser alloc] init];
	NSDictionary *interactions = [parser codePointInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertNil(interactions, @"Interactions should be nil");
	
	json = @"[]";
	interactions = [parser codePointInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertNil(interactions, @"Interactions should be nil");
	
	json = @"{}";
	interactions = [parser codePointInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertEqualObjects(@{}, interactions, @"Should be empty");
	
	json = @"{\"interactions\":[]}";
	interactions = [parser codePointInteractionsForEngagementManifest:[json dataUsingEncoding:NSUTF8StringEncoding]];
	XCTAssertNil(interactions, @"Interactions should be nil");
}

- (void)testCustomDataAndExtendedData {
	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil fromViewController:nil], @"nil custom data should not throw exception!");
	XCTAssertNoThrow([[ATConnect sharedConnection] engage:@"test_event" withCustomData:nil withExtendedData:nil fromViewController:nil], @"nil custom data or extended data should not throw exception!");
}

- (void)testCustomDeviceDataCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"device/custom_data/test_device_custom_data": @"test_value"};

	XCTAssertFalse([interaction criteriaAreMet], @"Criteria should not be met before adding custom data.");
	
	[[ATConnect sharedConnection] addCustomDeviceData:@"test_value" withKey:@"test_device_custom_data"];
	
	XCTAssertTrue([interaction criteriaAreMet], @"Criteria should be met after adding custom data.");

	interaction.criteria = @{@"device/custom_data/test_device_custom_data": @"test_value",
							 @"device/custom_data/test_version": @"4.5.1"};
	
	XCTAssertFalse([interaction criteriaAreMet], @"Criteria should not be met before adding custom data.");

	[[ATConnect sharedConnection] addCustomDeviceData:@"4.5.1" withKey:@"test_version"];

	XCTAssertTrue([interaction criteriaAreMet], @"Criteria should be met after adding custom data.");
}

- (void)testCustomPersonDataCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	interaction.criteria = @{@"person/custom_data/hair_color": @"black"};
	
	XCTAssertFalse([interaction criteriaAreMet], @"Criteria should not be met before adding custom data.");
	
	[[ATConnect sharedConnection] addCustomPersonData:@"black" withKey:@"hair_color"];
	
	XCTAssertTrue([interaction criteriaAreMet], @"Criteria should be met after adding custom data.");
	
	interaction.criteria = @{@"person/custom_data/hair_color": @"black",
							 @"person/custom_data/age": @"27"};
	
	XCTAssertFalse([interaction criteriaAreMet], @"Criteria should not be met before adding custom data.");
	
	[[ATConnect sharedConnection] addCustomPersonData:@"27" withKey:@"age"];
	
	XCTAssertTrue([interaction criteriaAreMet], @"Criteria should be met after adding custom data.");
}

- (void)testWillShowInteractionForEvent {
	ATInteraction *willShow = [[ATInteraction alloc] init];
	willShow.criteria = @{};
	willShow.type = @"Survey";
	
	ATInteraction *willNotShow = [[ATInteraction alloc] init];
	willNotShow.criteria = @{@"cannot_parse_criteria": @"cannot_parse_criteria"};
	willShow.type = @"Survey";
	
	NSDictionary *codePointInteractions = @{[ATEngagementBackend codePointForLocalEvent:@"willShow"]: @[willShow],
											[ATEngagementBackend codePointForLocalEvent:@"willNotShow"]: @[willNotShow]};
	
	
	[[ATEngagementBackend sharedBackend] didReceiveNewCodePointInteractions:codePointInteractions maxAge:60];
	
	XCTAssertTrue([willShow isValid], @"Event should be valid.");
	XCTAssertTrue([[ATConnect sharedConnection] willShowInteractionForEvent:@"willShow"], @"If interaction is valid, it will be shown for the next targeted event.");
	
	XCTAssertFalse([willNotShow isValid], @"Event should not be valid.");
	XCTAssertFalse([[ATConnect sharedConnection] willShowInteractionForEvent:@"willNotShow"], @"If interaction is not valid, it will not be shown for the next targeted event.");
}

@end
