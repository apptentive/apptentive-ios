//
//  ApptentiveSessionTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/23/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveSession.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveVersion.h"
#import "ApptentiveCount.h"
#import "ApptentiveMutablePerson.h"
#import "ApptentiveMutableDevice.h"

@interface ApptentiveSessionTests : XCTestCase <ApptentiveSessionDelegate>

@property (strong, nonatomic) ApptentiveSession *session;
@property (strong, nonatomic) NSDictionary *personDiffs;
@property (strong, nonatomic) NSDictionary *deviceDiffs;
@property (strong, nonatomic) NSDictionary *conversationPayload;
@property (assign, nonatomic) BOOL userInfoChanged;

@end

@implementation ApptentiveSessionTests

- (void)setUp {
    [super setUp];

	self.session = [[ApptentiveSession alloc] initWithAPIKey:@"ABC123"];
	self.session.delegate = self;
}

- (void)testSession {
	XCTAssertEqualObjects(self.session.APIKey, @"ABC123");
	XCTAssertNil(self.session.token);
	XCTAssertNil(self.session.person.identifier);
	XCTAssertNil(self.session.device.identifier);

	[self.session setToken:@"DEF456" personID:@"GHI789" deviceID:@"JKL101"];

	XCTAssertEqualObjects(self.session.token, @"DEF456");
	XCTAssertEqualObjects(self.session.person.identifier, @"GHI789");
	XCTAssertEqualObjects(self.session.device.identifier, @"JKL101");

	XCTAssertEqualObjects(self.session.userInfo, @{});
	XCTAssertFalse(self.userInfoChanged);

	[self.session setUserInfo:@"foo" forKey:@"bar"];
	XCTAssertEqualObjects(self.session.userInfo[@"bar"], @"foo");
	XCTAssertTrue(self.userInfoChanged);

	[self.session setUserInfo:@"foo1" forKey:@"bar"];
	XCTAssertEqualObjects(self.session.userInfo[@"bar"], @"foo1");

	[self.session removeUserInfoForKey:@"bar"];
	XCTAssertNil(self.session.userInfo[@"bar"]);

	XCTAssertNil(self.conversationPayload);

	[self.session.appRelease setValue:ApptentiveSDK.SDKVersion forKey:@"version"];

	[self.session checkForDiffs];

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
	XCTAssertEqualObjects(self.session.appRelease.type, @"ios");
	XCTAssertFalse(self.session.appRelease.hasAppStoreReceipt);
#if APPTENTIVE_DEBUG
	XCTAssertTrue(self.session.appRelease.debugBuild);
#else
	XCTAssertFalse(self.session.appRelease.debugBuild);
#endif

	XCTAssertFalse(self.session.appRelease.isUpdateBuild);
	XCTAssertFalse(self.session.appRelease.isUpdateVersion);
	XCTAssertFalse(self.session.appRelease.isOverridingStyles);

	[self.session didOverrideStyles];

	XCTAssertTrue(self.session.appRelease.isOverridingStyles);
}

- (void)testSDK {
	XCTAssertEqualObjects(self.session.SDK.authorName, @"Apptentive, Inc.");
	XCTAssertEqualObjects(self.session.SDK.distributionName, @"source");
	XCTAssertEqualObjects(self.session.SDK.distributionVersion, ApptentiveSDK.SDKVersion);
	XCTAssertEqualObjects(self.session.SDK.platform, @"iOS");
	XCTAssertEqualObjects(self.session.SDK.programmingLanguage, @"Objective-C");
	XCTAssertEqualObjects(self.session.SDK.version, ApptentiveSDK.SDKVersion);
}

- (void)testPerson {
	XCTAssertNil(self.session.person.name);
	XCTAssertNil(self.session.person.emailAddress);
	XCTAssertEqual(self.session.person.customData.count, (NSUInteger)0);

	[self.session updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = @"Testy McTesterson";
		person.emailAddress = @"test@apptentive.com";

		[person addCustomString:@"bar" withKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"five"];
		[person addCustomBool:YES withKey:@"yes"];
	}];

	NSDictionary *personDiffs = self.personDiffs[@"person"];
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], @"Testy McTesterson");
	XCTAssertEqualObjects(personDiffs[@"email"], @"test@apptentive.com");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"foo"], @"bar");
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"five"], @5);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @YES);
	self.personDiffs = nil;

	XCTAssertEqualObjects(self.session.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(self.session.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(self.session.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.session.person.customData[@"five"], @5);
	XCTAssertEqualObjects(self.session.person.customData[@"yes"], @YES);

	[self.session updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = nil;
		person.emailAddress = nil;

		[person removeCustomValueWithKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"yes"];
	}];

	personDiffs = self.personDiffs[@"person"];
	XCTAssertNotNil(personDiffs);
	XCTAssertEqualObjects(personDiffs[@"name"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"email"], [NSNull null]);
	XCTAssertEqualObjects(personDiffs[@"custom_data"][@"yes"], @5);

	XCTAssertNil(self.session.person.name);
	XCTAssertNil(self.session.person.emailAddress);
	XCTAssertNil(self.session.person.customData[@"foo"]);
	XCTAssertEqualObjects(self.session.person.customData[@"yes"], @5);
}

- (void)testDevice {
	XCTAssertNotNil(self.session.device.hardware);
	XCTAssertNotNil(self.session.device.localeRaw);
	XCTAssertNotNil(self.session.device.localeLanguageCode);
	XCTAssertNotNil(self.session.device.localeCountryCode);
	XCTAssertEqualObjects(self.session.device.OSName, @"iOS");
	XCTAssertEqual(self.session.device.UUID.UUIDString.length, (NSUInteger)36);
	XCTAssertEqual(self.session.device.customData.count, (NSUInteger)0);

	[self.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:@"bar" withKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"five"];
		[device addCustomBool:YES withKey:@"yes"];
	}];

	NSDictionary *deviceDiffs = self.deviceDiffs[@"device"];
	XCTAssertNotNil(deviceDiffs);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"foo"], @"bar");
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"five"], @5);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"yes"], @YES);
	self.deviceDiffs = nil;

	XCTAssertEqualObjects(self.session.device.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.session.device.customData[@"five"], @5);
	XCTAssertEqualObjects(self.session.device.customData[@"yes"], @YES);

	XCTAssertNotNil(self.session.device.localeRaw);
	XCTAssertNotNil(self.session.device.localeLanguageCode);
	XCTAssertNotNil(self.session.device.localeCountryCode);
	XCTAssertEqualObjects(self.session.device.OSName, @"iOS");
	XCTAssertEqual(self.session.device.UUID.UUIDString.length, (NSUInteger)36);

	[self.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device removeCustomValueWithKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"yes"];
	}];

	deviceDiffs = self.deviceDiffs[@"device"];
	XCTAssertNotNil(deviceDiffs);
	XCTAssertEqualObjects(deviceDiffs[@"custom_data"][@"yes"], @5);

	XCTAssertNil(self.session.device.customData[@"foo"]);
	XCTAssertEqualObjects(self.session.device.customData[@"yes"], @5);
}

- (void)testEngagement {
	XCTAssertNotNil(self.session.engagement.codePoints);
	XCTAssertNotNil(self.session.engagement.interactions);

	[self.session.engagement warmCodePoint:@"test.code.point"];

	ApptentiveCount *testCodePoint = self.session.engagement.codePoints[@"test.code.point"];
	XCTAssertNotNil(testCodePoint);
	XCTAssertEqual(testCodePoint.totalCount, 0);
	XCTAssertEqual(testCodePoint.buildCount, 0);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertNil(testCodePoint.lastInvoked);

	[self.session.engagement engageCodePoint:@"test.code.point"];

	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 1);
	XCTAssertEqual(testCodePoint.versionCount, 1);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.session.engagement warmInteraction:@"test.interaction"];

	ApptentiveCount *testInteraction = self.session.engagement.interactions[@"test.interaction"];
	XCTAssertNotNil(testInteraction);
	XCTAssertEqual(testInteraction.totalCount, 0);
	XCTAssertEqual(testInteraction.buildCount, 0);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertNil(testInteraction.lastInvoked);

	[self.session.engagement engageInteraction:@"test.interaction"];

	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 1);
	XCTAssertEqual(testInteraction.versionCount, 1);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.session.engagement resetBuild];

	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 0);
	XCTAssertEqual(testCodePoint.versionCount, 1);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 0);
	XCTAssertEqual(testInteraction.versionCount, 1);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [[NSDate date] timeIntervalSince1970], 0.01);

	[self.session.engagement resetVersion];

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
	[self.session setToken:@"DEF456" personID:@"GHI789" deviceID:@"JKL101"];
	[self.session setUserInfo:@"foo" forKey:@"bar"];

	[self.session didOverrideStyles];

	[self.session updatePerson:^(ApptentiveMutablePerson *person) {
		person.name = @"Testy McTesterson";
		person.emailAddress = @"test@apptentive.com";

		[person addCustomString:@"bar" withKey:@"foo"];
		[person addCustomNumber:@(5) withKey:@"five"];
		[person addCustomBool:YES withKey:@"yes"];
	}];

	[self.session updateDevice:^(ApptentiveMutableDevice *device) {
		[device addCustomString:@"bar" withKey:@"foo"];
		[device addCustomNumber:@(5) withKey:@"five"];
		[device addCustomBool:YES withKey:@"yes"];
	}];

	[self.session.engagement engageCodePoint:@"test.code.point"];
	[self.session.engagement engageInteraction:@"test.interaction"];
	NSDate *engagementTime = [NSDate date];
	[self.session.engagement resetVersion];

	NSString *path = [NSTemporaryDirectory() stringByAppendingString:@"session.archive"];

	[NSKeyedArchiver archiveRootObject:self.session toFile:path];

	ApptentiveSession *session = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

	XCTAssertEqualObjects(session.token, @"DEF456");
	XCTAssertEqualObjects(session.person.identifier, @"GHI789");
	XCTAssertEqualObjects(session.device.identifier, @"JKL101");
	XCTAssertEqualObjects(self.session.userInfo[@"bar"], @"foo");

	XCTAssertTrue(session.appRelease.isOverridingStyles);

	XCTAssertEqualObjects(self.session.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(self.session.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(self.session.person.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.session.person.customData[@"five"], @5);
	XCTAssertEqualObjects(self.session.person.customData[@"yes"], @YES);

	XCTAssertNotNil(self.session.device.hardware);
	XCTAssertNotNil(self.session.device.localeRaw);
	XCTAssertNotNil(self.session.device.localeLanguageCode);
	XCTAssertNotNil(self.session.device.localeCountryCode);
	XCTAssertEqualObjects(self.session.device.OSName, @"iOS");
	XCTAssertEqual(self.session.device.UUID.UUIDString.length, (NSUInteger)36);
	XCTAssertEqualObjects(self.session.device.customData[@"foo"], @"bar");
	XCTAssertEqualObjects(self.session.device.customData[@"five"], @5);
	XCTAssertEqualObjects(self.session.device.customData[@"yes"], @YES);

	ApptentiveCount *testCodePoint = self.session.engagement.codePoints[@"test.code.point"];
	XCTAssertEqual(testCodePoint.totalCount, 1);
	XCTAssertEqual(testCodePoint.buildCount, 1);
	XCTAssertEqual(testCodePoint.versionCount, 0);
	XCTAssertEqualWithAccuracy(testCodePoint.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);

	ApptentiveCount *testInteraction = self.session.engagement.interactions[@"test.interaction"];
	XCTAssertEqual(testInteraction.totalCount, 1);
	XCTAssertEqual(testInteraction.buildCount, 1);
	XCTAssertEqual(testInteraction.versionCount, 0);
	XCTAssertEqualWithAccuracy(testInteraction.lastInvoked.timeIntervalSince1970, [engagementTime timeIntervalSince1970], 0.01);
}

#pragma mark - Session delegate

- (void)session:(ApptentiveSession *)session deviceDidChange:(NSDictionary *)diffs {
	self.deviceDiffs = diffs;
}

- (void)session:(ApptentiveSession *)session personDidChange:(NSDictionary *)diffs {
	self.personDiffs = diffs;
}

- (void)session:(ApptentiveSession *)session conversationDidChange:(NSDictionary *)payload {
	self.conversationPayload = payload;
}

- (void)sessionUserInfoDidChange:(ApptentiveSession *)session {
	self.userInfoChanged = YES;
}

@end
