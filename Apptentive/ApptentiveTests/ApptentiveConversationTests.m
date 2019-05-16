//
//  ApptentiveConversationTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/23/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAppRelease.h"
#import "ApptentiveConversation.h"
#import "ApptentiveCount.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"
#import <XCTest/XCTest.h>


@interface ApptentiveConversationTests : XCTestCase <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversation *conversation;
@property (strong, nonatomic) NSDictionary *personDiffs;
@property (strong, nonatomic) NSDictionary *deviceDiffs;
@property (assign, nonatomic) BOOL userInfoChanged;
@property (assign, nonatomic) BOOL engagementChanged;

@end


@implementation ApptentiveConversationTests

- (void)setUp {
	[super setUp];

	[ApptentiveDevice getPermanentDeviceValues];

	self.conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];
	self.conversation.delegate = self;
}

- (void)testConversation {
	XCTAssertNil(self.conversation.token);
	XCTAssertNil(self.conversation.person.identifier);
	XCTAssertNil(self.conversation.device.identifier);

	XCTAssertEqualObjects(self.conversation.userInfo, @{});
	XCTAssertFalse(self.userInfoChanged);

	[self.conversation setUserInfo:@"foo" forKey:@"bar"];
	XCTAssertEqualObjects(self.conversation.userInfo[@"bar"], @"foo");
	XCTAssertTrue(self.userInfoChanged);

	[self.conversation setUserInfo:@"foo1" forKey:@"bar"];
	XCTAssertEqualObjects(self.conversation.userInfo[@"bar"], @"foo1");

	[self.conversation removeUserInfoForKey:@"bar"];
	XCTAssertNil(self.conversation.userInfo[@"bar"]);

	[self.conversation.appRelease setValue:ApptentiveSDK.SDKVersion forKey:@"version"];

	[self.conversation checkForDiffs];

	XCTAssertNil(self.conversation.sessionIdentifier);

	[self.conversation startSession];

	XCTAssertEqual(self.conversation.sessionIdentifier.length, 32);

	[self.conversation endSession];

	XCTAssertNil(self.conversation.sessionIdentifier);
}

- (void)testAppRelease {
	XCTAssertEqualObjects(self.conversation.appRelease.type, @"ios");
	XCTAssertFalse(self.conversation.appRelease.hasAppStoreReceipt);
#if APPTENTIVE_DEBUG
	XCTAssertTrue(self.conversation.appRelease.debugBuild);
#else
	XCTAssertFalse(self.conversation.appRelease.debugBuild);
#endif

    XCTAssertEqualObjects(self.conversation.appRelease.bundleIdentifier, @"com.apple.dt.xctest.tool");

	XCTAssertFalse(self.conversation.appRelease.isUpdateBuild);
	XCTAssertFalse(self.conversation.appRelease.isUpdateVersion);
	XCTAssertFalse(self.conversation.appRelease.isOverridingStyles);

	[self.conversation didOverrideStyles];

	XCTAssertTrue(self.conversation.appRelease.isOverridingStyles);
}

- (void)testSDK {
	XCTAssertEqualObjects(self.conversation.SDK.authorName, @"Apptentive, Inc.");
	XCTAssertEqualObjects(self.conversation.SDK.distributionName, @"source");
	XCTAssertEqualObjects(self.conversation.SDK.distributionVersion, ApptentiveSDK.SDKVersion);
	XCTAssertEqualObjects(self.conversation.SDK.platform, @"iOS");
	XCTAssertEqualObjects(self.conversation.SDK.programmingLanguage, @"Objective-C");
	XCTAssertEqualObjects(self.conversation.SDK.version, ApptentiveSDK.SDKVersion);
}

- (void)testPerson {
	XCTAssertNil(self.conversation.person.name);
	XCTAssertNil(self.conversation.person.emailAddress);
	XCTAssertNil(self.conversation.person.mParticleId);
	XCTAssertEqual(self.conversation.person.customData.count, (NSUInteger)0);

	self.conversation.person.name = @"Testy McTesterson";
	self.conversation.person.emailAddress = @"test@apptentive.com";
	self.conversation.person.mParticleId = @"0123456789ABCDEF";

	[self.conversation.person addCustomString:@"bar" withKey:@"foo"];
	[self.conversation.person addCustomNumber:@(5) withKey:@"five"];
	[self.conversation.person addCustomBool:YES withKey:@"yes"];

	[self.conversation checkForPersonDiffs];

	NSDictionary *personDiffs = self.personDiffs;
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], @"Testy McTesterson");
	XCTAssertEqualObjects(personDiffs[@"email"], @"test@apptentive.com");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"foo"], @"bar");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"five"], @5);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @YES);
	XCTAssertEqualObjects(personDiffs[@"mparticle_id"], @"0123456789ABCDEF");
	self.personDiffs = nil;

	XCTAssertEqualObjects(self.conversation.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(self.conversation.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(self.conversation.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.conversation.person.customData[@"five"], @5);
	XCTAssertEqualObjects(self.conversation.person.customData[@"yes"], @YES);
	XCTAssertEqualObjects(self.conversation.person.mParticleId, @"0123456789ABCDEF");

	self.conversation.person.name = nil;
	self.conversation.person.emailAddress = nil;

	[self.conversation.person removeCustomValueWithKey:@"foo"];
	[self.conversation.person addCustomNumber:@(5) withKey:@"yes"];

	[self.conversation checkForPersonDiffs];

	personDiffs = self.personDiffs;
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"email"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @5);
	XCTAssertNil(personDiffs[@"mparticle_id"]);

	XCTAssertNil(self.conversation.person.name);
	XCTAssertNil(self.conversation.person.emailAddress);
	XCTAssertNil(self.conversation.person.customData[@"foo"]);
	XCTAssertEqualObjects(self.conversation.person.customData[@"yes"], @5);
}

- (void)testDevice {
	XCTAssertNotNil(self.conversation.device.hardware);
	XCTAssertNotNil(self.conversation.device.localeRaw);
	XCTAssertNotNil(self.conversation.device.localeLanguageCode);
	XCTAssertNotNil(self.conversation.device.localeCountryCode);
	XCTAssertEqualObjects(self.conversation.device.OSName, @"iOS");
	XCTAssertEqual(self.conversation.device.UUID.UUIDString.length, (NSUInteger)36);
	XCTAssertEqual(self.conversation.device.customData.count, (NSUInteger)0);

	[self.conversation.device addCustomString:@"bar" withKey:@"foo"];
	[self.conversation.device addCustomNumber:@(5) withKey:@"five"];
	[self.conversation.device addCustomBool:YES withKey:@"yes"];

	[self.conversation checkForDeviceDiffs];

	NSDictionary *deviceDiffs = self.deviceDiffs;
	XCTAssertNotNil(deviceDiffs);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"foo"], @"bar");
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"five"], @5);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"yes"], @YES);
	self.deviceDiffs = nil;

	XCTAssertEqualObjects(self.conversation.device.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.conversation.device.customData[@"five"], @5);
	XCTAssertEqualObjects(self.conversation.device.customData[@"yes"], @YES);

	XCTAssertNotNil(self.conversation.device.localeRaw);
	XCTAssertNotNil(self.conversation.device.localeLanguageCode);
	XCTAssertNotNil(self.conversation.device.localeCountryCode);
	XCTAssertEqualObjects(self.conversation.device.OSName, @"iOS");
	XCTAssertEqual(self.conversation.device.UUID.UUIDString.length, (NSUInteger)36);

	[self.conversation.device removeCustomValueWithKey:@"foo"];
	[self.conversation.device addCustomNumber:@(5) withKey:@"yes"];

	[self.conversation checkForDeviceDiffs];

	deviceDiffs = self.deviceDiffs;
	XCTAssertNotNil(deviceDiffs);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"yes"], @5);

	XCTAssertNil(self.conversation.device.customData[@"foo"]);
	XCTAssertEqualObjects(self.conversation.device.customData[@"yes"], @5);
}

- (void)testEngagement {
	XCTAssertNotNil(self.conversation.engagement.codePoints);
	XCTAssertNotNil(self.conversation.engagement.interactions);

	[self.conversation.engagement warmCodePoint:@"test.code.point"];

	ApptentiveCount *testCodePoint = self.conversation.engagement.codePoints[@"test.code.point"];
	XCTAssertNotNil(testCodePoint);
	XCTAssertEqual(testCodePoint.totalCount, 0);
	XCTAssertEqual(testCodePoint.buildCount, 0);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertNil(testCodePoint.lastInvoked);

	[self.conversation.engagement engageCodePoint:@"test.code.point"];

	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 1);
	XCTAssertEqual(testCodePoint.versionCount, 1);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.conversation.engagement warmInteraction:@"test.interaction"];

	ApptentiveCount *testInteraction = self.conversation.engagement.interactions[@"test.interaction"];
	XCTAssertNotNil(testInteraction);
	XCTAssertEqual(testInteraction.totalCount, 0);
	XCTAssertEqual(testInteraction.buildCount, 0);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertNil(testInteraction.lastInvoked);

	[self.conversation.engagement engageInteraction:@"test.interaction"];

	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 1);
	XCTAssertEqual(testInteraction.versionCount, 1);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.conversation.engagement resetBuild];

	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 0);
	XCTAssertEqual(testCodePoint.versionCount, 1);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 0);
	XCTAssertEqual(testInteraction.versionCount, 1);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.conversation.engagement resetVersion];

	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 0);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 0);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);
}

- (void)testNSCoding {
	ApptentiveMutableConversation *mutableConversation = [self.conversation mutableCopy];

	// Make some changes to the default values
	[mutableConversation setToken:@"DEF456" conversationID:@"ABC123" personID:@"GHI789" deviceID:@"JKL101"];
	[mutableConversation setUserInfo:@"foo" forKey:@"bar"];

	[mutableConversation didOverrideStyles];

	mutableConversation.person.name = @"Testy McTesterson";
	mutableConversation.person.emailAddress = @"test@apptentive.com";
	mutableConversation.person.mParticleId = @"ABCDEF0123456789";

	[mutableConversation.person addCustomString:@"bar" withKey:@"foo"];
	[mutableConversation.person addCustomNumber:@(5) withKey:@"five"];
	[mutableConversation.person addCustomBool:YES withKey:@"yes"];

	[mutableConversation.device addCustomString:@"bar" withKey:@"foo"];
	[mutableConversation.device addCustomNumber:@(5) withKey:@"five"];
	[mutableConversation.device addCustomBool:YES withKey:@"yes"];

	[mutableConversation.engagement engageCodePoint:@"test.code.point"];
	[mutableConversation.engagement engageInteraction:@"test.interaction"];
	NSDate *engagementTime = [NSDate date];
	[mutableConversation.engagement resetVersion];

	[mutableConversation startSession];

	NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"conversation.archive"];

	[NSKeyedArchiver archiveRootObject:mutableConversation toFile:path];

	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

	XCTAssertEqualObjects(conversation.userInfo[@"bar"], @"foo");

	XCTAssertTrue(conversation.appRelease.isOverridingStyles);

	XCTAssertEqualObjects(conversation.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(conversation.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(conversation.person.mParticleId, @"ABCDEF0123456789");
	XCTAssertEqualObjects(conversation.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(conversation.person.customData[@"five"], @5);
	XCTAssertEqualObjects(conversation.person.customData[@"yes"], @YES);

	XCTAssertNotNil(conversation.device.hardware);
	XCTAssertNotNil(conversation.device.localeRaw);
	XCTAssertNotNil(conversation.device.localeLanguageCode);
	XCTAssertNotNil(conversation.device.localeCountryCode);
	XCTAssertEqualObjects(conversation.device.OSName, @"iOS");
	XCTAssertEqual(conversation.device.UUID.UUIDString.length, (NSUInteger)36);
	XCTAssertEqualObjects(conversation.device.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(conversation.device.customData[@"five"], @5);
	XCTAssertEqualObjects(conversation.device.customData[@"yes"], @YES);

	ApptentiveCount *testCodePoint = conversation.engagement.codePoints[@"test.code.point"];
	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 1);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);

	ApptentiveCount *testInteraction = conversation.engagement.interactions[@"test.interaction"];
	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 1);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);

	XCTAssertNil(conversation.sessionIdentifier);
}

- (void)testResetDeviceDiffs {
	[self.conversation updateLastSentDevice];
	[self.conversation checkForDeviceDiffs];

	XCTAssertNil(self.deviceDiffs);

	[self.conversation.device addCustomString:@"foo" withKey:@"bar"];
	[self.conversation checkForDeviceDiffs];

	XCTAssertEqualObjects(self.deviceDiffs, @{ @"custom_data": @{ @"bar": @"foo"}});

	self.deviceDiffs = nil;
	[self.conversation.device addCustomString:@"bar" withKey:@"foo"];
	[self.conversation updateLastSentDevice];
	[self.conversation checkForDeviceDiffs];

	XCTAssertNil(self.deviceDiffs);
}

#pragma mark - Conversation delegate

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	self.deviceDiffs = diffs;
}

- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	self.personDiffs = diffs;
}

- (void)conversationAppReleaseOrSDKDidChange:(ApptentiveConversation *)conversation {
}

- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
	self.userInfoChanged = YES;
}

- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
	self.engagementChanged = YES;
}

@end
