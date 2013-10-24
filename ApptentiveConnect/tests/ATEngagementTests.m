//
//  ATEngagementTests.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 9/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEngagementTests.h"
#import "ATInteraction.h"
#import "ATInteractionUsageData.h"

@implementation ATEngagementTests

/*
 days_since_install - The total number of days since the app was first launched (irrespective of app version).  (integer)
 days_since_upgrade - The number of days since the current version of the app was first launched.  (integer)
 application_version - The currently running application version (string).
 code_point.code_point_name.invokes.total - The total number of times code_point_name has been invoked across all versions of the app (regardless if an Interaction was shown at that point)  (integer)
 code_point.code_point_name.invokes.version - The number of times code_point_name has been invoked in the current version of the app (regardless if an Interaction was shown at that point) (integer)
 interactions.interaction_instance_id.invokes.total - The number of times the Interaction Instance with id interaction_instance_id has been invoked (irrespective of app version) (integer)
 interactions.interaction_instance_id.invokes.version  - The number of times the Interaction Instance with id interaction_instance_id has been invoked within the current version of the app (integer)
*/

- (void)testInteractionCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData;
	
	interaction.criteria = @{@"days_since_install" : @{@"$gt" : @5, @"$lt" : @7}};
	usageData = [ATInteractionUsageData usageDataForInteraction:interaction
													atCodePoint:@"code.point"
											   daysSinceInstall:@6
											   daysSinceUpgrade:@6
											 applicationVersion:@"1.8.9"
										  codePointInvokesTotal:@8
										codePointInvokesVersion:@8
										interactionInvokesTotal:@8
									  interactionInvokesVersion:@8];
	
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testInteractionCriteriaDaysSinceInstall {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"days_since_install" : @6};
	usageData.daysSinceInstall = @6;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @7;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"days_since_install" : @{@"$gt" : @5, @"$lt" : @7}};
	usageData.daysSinceInstall = @6;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @7;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	
	interaction.criteria = @{@"days_since_install" : @{@"$lte" : @5, @"$gt" : @3}};
	usageData.daysSinceInstall = @3;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @4;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @5;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Install date");
	usageData.daysSinceInstall = @6;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Install date");
}

- (void)testInteractionCriteriaVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"application_version" : @"1.2.8"};
	usageData.applicationVersion = @"1.2.8";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"v1.2.8";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
	
	interaction.criteria = @{@"application_version" : @"v3.0"};
	usageData.applicationVersion = @"v3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Version number");
	usageData.applicationVersion = @"3.0";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Version number must not have a 'v' in front!");
}

- (void)testCodePointInvokesVersion {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version" : @1};
	usageData.codePoint = @"app.launch";
	usageData.codePointInvokesVersion = @1;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"This version has been invoked 1 time.");
	usageData.codePointInvokesVersion = @0;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @2;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	
	interaction.criteria = @{@"code_point/big.win/invokes/version" : @7};
	usageData.codePoint = @"big.win";
	usageData.codePointInvokesVersion = @7;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @1;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @19;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");

	interaction.criteria = @{@"code_point/big.win/invokes/version" : @{@"$gte" : @5, @"$lte" : @5}};
	usageData.codePoint = @"big.win";
	usageData.codePointInvokesVersion = @5;
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @3;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
	usageData.codePointInvokesVersion = @19;
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Codepoint version invokes.");
}

- (void)testUpgradeMessageCriteria {
	ATInteraction *interaction = [[ATInteraction alloc] init];
	ATInteractionUsageData *usageData = [[ATInteractionUsageData alloc] init];
	usageData.codePoint = @"app.launch";
	
	interaction.criteria = @{@"code_point/app.launch/invokes/version" : @1,
							 @"application_version" : @"1.3.0"};
	usageData.codePointInvokesVersion = @1;
	usageData.applicationVersion = @"1.3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @2;
	usageData.applicationVersion = @"1.3.0";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @1;
	usageData.applicationVersion = @"1.3.1";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");

	interaction.criteria = @{@"application_version" : @"1.3.0",
							 @"code_point/app.launch/invokes/version" : @{@"$gte" : @1}};
	usageData.codePointInvokesVersion = @1;
	usageData.applicationVersion = @"1.3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @2;
	usageData.applicationVersion = @"1.3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @0;
	usageData.applicationVersion = @"1.3.0";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	
	interaction.criteria = @{@"application_version" : @"1.3.0",
							 @"code_point/app.launch/invokes/version" : @{@"$lte" : @4}};
	usageData.codePointInvokesVersion = @1;
	usageData.applicationVersion = @"1.3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @4;
	usageData.applicationVersion = @"1.3.0";
	STAssertTrue([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
	usageData.codePointInvokesVersion = @5;
	usageData.applicationVersion = @"1.3.0";
	STAssertFalse([interaction criteriaAreMetForUsageData:usageData], @"Test Upgrade Message.");
}

@end
