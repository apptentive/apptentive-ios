//
//  ApptentiveConversationTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/23/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveConversation.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveVersion.h"
#import "ApptentiveCount.h"
#import "ApptentiveMutablePerson.h"
#import "ApptentiveMutableDevice.h"


@interface ApptentiveConversationTests : XCTestCase <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversation *conversation;
@property (strong, nonatomic) NSDictionary *personDiffs;
@property (strong, nonatomic) NSDictionary *deviceDiffs;
@property (strong, nonatomic) NSDictionary *conversationPayload;
@property (assign, nonatomic) BOOL userInfoChanged;
@property (assign, nonatomic) BOOL engagementChanged;

@end


@implementation ApptentiveConversationTests

- (void)setUp {
	[super setUp];

	self.conversation = [[ApptentiveConversation alloc] init];
	self.conversation.delegate = self;
}

- (void)testConversation {
	XCTAssertNil(self.conversation.token);
	XCTAssertNil(self.conversation.person.identifier);
	XCTAssertNil(self.conversation.device.identifier);

	[self.conversation setToken:@"DEF456" conversationID:@"ABC123" personID:@"GHI789" deviceID:@"JKL101"];

	XCTAssertEqualObjects(self.conversation.token, @"DEF456");
	XCTAssertEqualObjects(self.conversation.person.identifier, @"GHI789");
	XCTAssertEqualObjects(self.conversation.device.identifier, @"JKL101");

	XCTAssertEqualObjects(self.conversation.userInfo, @{});
	XCTAssertFalse(self.userInfoChanged);

	[self.conversation setUserInfo:@"foo" forKey:@"bar"];
	XCTAssertEqualObjects(self.conversation.userInfo[@"bar"], @"foo");
	XCTAssertTrue(self.userInfoChanged);

	[self.conversation setUserInfo:@"foo1" forKey:@"bar"];
	XCTAssertEqualObjects(self.conversation.userInfo[@"bar"], @"foo1");

	[self.conversation removeUserInfoForKey:@"bar"];
	XCTAssertNil(self.conversation.userInfo[@"bar"]);

	XCTAssertNil(self.conversationPayload);

	[self.conversation.appRelease setValue:ApptentiveSDK.SDKVersion forKey:@"version"];

	[self.conversation checkForDiffs];

#if APPTENTIVE_DEBUG
	NSNumber *isDebug = @YES;
#else
	NSNumber *isDebug = @NO;
#endif

	XCTAssertNotNil(self.conversationPayload);
	NSDictionary *appRelease = self.conversationPayload[@"app_release"];
	XCTAssertNotNil(appRelease);
	XCTAssertEqualObjects(appRelease[@"app_store_receipt"][@"has_receipt"], @NO);
	XCTAssertEqualObjects(appRelease[@"debug"], isDebug);
	XCTAssertEqualObjects(appRelease[@"overriding_styles"], @NO);
	XCTAssertEqualObjects(appRelease[@"type"], @"ios");

	NSDictionary *SDK = self.conversationPayload[@"sdk"];
	XCTAssertNotNil(SDK);
	XCTAssertEqualObjects(SDK[@"author_name"], @"Apptentive, Inc.");
	XCTAssertEqualObjects(SDK[@"distribution"], @"source");
	XCTAssertEqualObjects(SDK[@"distribution_version"], ApptentiveSDK.SDKVersion.versionString);
	XCTAssertEqualObjects(SDK[@"platform"], @"iOS");
	XCTAssertEqualObjects(SDK[@"programming_language"], @"Objective-C");
	XCTAssertEqualObjects(SDK[@"version"], ApptentiveSDK.SDKVersion.versionString);
}

- (void)testAppRelease {
	XCTAssertEqualObjects(self.conversation.appRelease.type, @"ios");
	XCTAssertFalse(self.conversation.appRelease.hasAppStoreReceipt);
#if APPTENTIVE_DEBUG
	XCTAssertTrue(self.conversation.appRelease.debugBuild);
#else
	XCTAssertFalse(self.conversation.appRelease.debugBuild);
#endif

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
	XCTAssertEqual(self.conversation.person.customData.count, (NSUInteger)0);

	[self.conversation updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = @"Testy McTesterson";
		person.emailAddress = @"test@apptentive.com";

		[person addCustomString:@"bar" withKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"five"];
		[person addCustomBool:YES withKey:@"yes"];
	}];

	NSDictionary *personDiffs = self.personDiffs;
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], @"Testy McTesterson");
	XCTAssertEqualObjects(personDiffs[@"email"], @"test@apptentive.com");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"foo"], @"bar");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"five"], @5);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @YES);
	self.personDiffs = nil;

	XCTAssertEqualObjects(self.conversation.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(self.conversation.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(self.conversation.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.conversation.person.customData[@"five"], @5);
	XCTAssertEqualObjects(self.conversation.person.customData[@"yes"], @YES);

	[self.conversation updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = nil;
		person.emailAddress = nil;

		[person removeCustomValueWithKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"yes"];
	}];

	personDiffs = self.personDiffs;
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"email"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @5);

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

	[self.conversation updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:@"bar" withKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"five"];
		[device addCustomBool:YES withKey:@"yes"];
	}];

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

	[self.conversation updateDevice:^(ApptentiveMutableDevice *device) {
		[device removeCustomValueWithKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"yes"];
	}];

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
	// Make some changes to the default values
	[self.conversation setToken:@"DEF456" conversationID:@"ABC123" personID:@"GHI789" deviceID:@"JKL101"];
	[self.conversation setUserInfo:@"foo" forKey:@"bar"];

	[self.conversation didOverrideStyles];

	[self.conversation updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = @"Testy McTesterson";
		person.emailAddress = @"test@apptentive.com";

		[person addCustomString:@"bar" withKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"five"];
		[person addCustomBool:YES withKey:@"yes"];
	}];

	[self.conversation updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:@"bar" withKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"five"];
		[device addCustomBool:YES withKey:@"yes"];
	}];

	[self.conversation.engagement engageCodePoint:@"test.code.point"];
	[self.conversation.engagement engageInteraction:@"test.interaction"];
	NSDate *engagementTime = [NSDate date];
	[self.conversation.engagement resetVersion];

	NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"conversation.archive"];

	[NSKeyedArchiver archiveRootObject:self.conversation toFile:path];

	ApptentiveConversation *conversation = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

	XCTAssertEqualObjects(conversation.token, @"DEF456");
	XCTAssertEqualObjects(conversation.person.identifier, @"GHI789");
	XCTAssertEqualObjects(conversation.device.identifier, @"JKL101");
	XCTAssertEqualObjects(self.conversation.userInfo[@"bar"], @"foo");

	XCTAssertTrue(conversation.appRelease.isOverridingStyles);

	XCTAssertEqualObjects(self.conversation.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(self.conversation.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(self.conversation.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.conversation.person.customData[@"five"], @5);
	XCTAssertEqualObjects(self.conversation.person.customData[@"yes"], @YES);

	XCTAssertNotNil(self.conversation.device.hardware);
	XCTAssertNotNil(self.conversation.device.localeRaw);
	XCTAssertNotNil(self.conversation.device.localeLanguageCode);
	XCTAssertNotNil(self.conversation.device.localeCountryCode);
	XCTAssertEqualObjects(self.conversation.device.OSName, @"iOS");
	XCTAssertEqual(self.conversation.device.UUID.UUIDString.length, (NSUInteger)36);
	XCTAssertEqualObjects(self.conversation.device.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.conversation.device.customData[@"five"], @5);
	XCTAssertEqualObjects(self.conversation.device.customData[@"yes"], @YES);

	ApptentiveCount *testCodePoint = self.conversation.engagement.codePoints[@"test.code.point"];
	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 1);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);

	ApptentiveCount *testInteraction = self.conversation.engagement.interactions[@"test.interaction"];
	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 1);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);
}

#pragma mark - Conversation delegate

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	self.deviceDiffs = diffs;
}

- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	self.personDiffs = diffs;
}

- (void)conversation:(ApptentiveConversation *)conversation appReleaseOrSDKDidChange:(NSDictionary *)payload {
	self.conversationPayload = payload;
}

- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
	self.userInfoChanged = YES;
}

- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
	self.engagementChanged = YES;
}

@end
