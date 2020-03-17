//
//  ApptentiveConversationMigrationTests.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/10/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ApptentiveAppDataContainer.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveConversation.h"
#import "ApptentiveCount.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentivePerson.h"
#import "ApptentiveEngagementManifest.h"
#import "ApptentiveLegacyEvent.h"
#import "ApptentiveLegacyMessage.h"
#import "ApptentiveLegacySurveyResponse.h"

#import "ApptentiveDataManager.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveUnarchiver.h"
#import "ApptentiveTargets.h"
#import "ApptentiveConversationMetadata.h"
#import "ApptentiveAppConfiguration.h"


static inline NSDate *dateFromString(NSString *date) {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
	[formatter setLocale:enUSPOSIXLocale];
	[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
	[formatter setCalendar:[NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian]];

	return [formatter dateFromString:date];
}


@interface ApptentiveConversationMigrationTests : XCTestCase

@end


@implementation ApptentiveConversationMigrationTests

- (void)setUp {
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (void)testConversationMigration {
	[ApptentiveAppDataContainer pushDataContainerWithName:@"3.5.0"];

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];
	XCTAssertNotNil(conversation);
	XCTAssertEqualObjects(conversation.legacyToken, @"1c496320bd0dbca0aad7e774f4eb3ec595f620e1df7a4afc9da37e5536bd5851");
	XCTAssertEqualObjects(conversation.person.identifier, @"59124f8d09e3da650e000037");
	XCTAssertEqualObjects(conversation.device.identifier, @"59124f8d09e3da650e000035");

	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallTotal, dateFromString(@"2017-04-01T12:00:00-0700"));
	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallVersion, dateFromString(@"2017-04-02T12:00:00-0700"));
	XCTAssertEqualObjects(conversation.appRelease.timeAtInstallBuild, dateFromString(@"2017-04-02T12:00:00-0700"));


	XCTAssertNotNil(conversation.SDK);

	XCTAssertNotNil(conversation.engagement);
	XCTAssertEqualObjects(conversation.engagement.interactions[@"interaction_1"].lastInvoked, dateFromString(@"2017-03-01T13:00:00-0700"));
	XCTAssertEqualObjects(conversation.engagement.interactions[@"interaction_2"].lastInvoked, dateFromString(@"2017-03-02T13:00:00-0700"));
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].buildCount, 1);
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].buildCount, 2);
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].totalCount, 3);
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].totalCount, 4);
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_1"].versionCount, 5);
	XCTAssertEqual(conversation.engagement.interactions[@"interaction_2"].versionCount, 6);

	NSDictionary *expectedPersonData = @{
		@"string": @"String Test",
		@"number": @22,
		@"boolean1": @NO,
		@"boolean2": @YES
	};

	XCTAssertEqualObjects(conversation.person.name, @"Testy McTesterson");
	XCTAssertEqualObjects(conversation.person.emailAddress, @"test@apptentive.com");
	XCTAssertEqualObjects(conversation.person.customData, expectedPersonData);

	NSDictionary *expectedDeviceData = @{
		@"string": @"Test String",
		@"number": @42,
		@"boolean1": @YES,
		@"boolean2": @NO
	};
	XCTAssertEqualObjects(conversation.device.customData, expectedDeviceData);
	XCTAssertEqualObjects(conversation.device.integrationConfiguration, @{ @"apptentive_push": @{@"token": @"abcdef123456"} });

	XCTAssertEqualObjects([conversation.engagement.codePoints[@"local#app#event_1"] lastInvoked], dateFromString(@"2017-02-01T13:00:00-0700"));
	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] buildCount], 1);
	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] versionCount], 2);
	XCTAssertEqual([conversation.engagement.codePoints[@"local#app#event_1"] totalCount], 3);
}

- (void)testEnqueueUnsentEvents {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *bundlePath = [bundle pathForResource:@"3.5.0" ofType:@"xcappdata"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
		XCTFail(@"App data doesn't exist: 3.5.0");
	}

	NSString *supportDirectoryPath = [bundlePath stringByAppendingString:@"/AppData/Library/Application Support/com.apptentive.feedback"];

	ApptentiveDataManager *dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:supportDirectoryPath];
	NSManagedObjectContext *context = dataManager.managedObjectContext;

	NSArray *beforeResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];

	[ApptentiveLegacyEvent enqueueUnsentEventsInContext:context forConversation:conversation];

	NSArray *afterResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	XCTAssertGreaterThan(afterResults.count, beforeResults.count);
}

- (void)testEnqueueUnsentMessages {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *bundlePath = [bundle pathForResource:@"3.5.0" ofType:@"xcappdata"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
		XCTFail(@"App data doesn't exist: 3.5.0");
	}

	NSString *supportDirectoryPath = [bundlePath stringByAppendingString:@"/AppData/Library/Application Support/com.apptentive.feedback"];

	ApptentiveDataManager *dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:supportDirectoryPath];
	NSManagedObjectContext *context = dataManager.managedObjectContext;

	NSArray *beforeResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];

	NSString *oldAttachmentPath = [supportDirectoryPath stringByAppendingString:@"/attachments"];

	[ApptentiveLegacyMessage enqueueUnsentMessagesInContext:context forConversation:conversation oldAttachmentPath:oldAttachmentPath newAttachmentPath:supportDirectoryPath];

	NSArray *afterResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	XCTAssertGreaterThan(afterResults.count, beforeResults.count);
}

- (void)testEnqueueUnsentSurveyResponses {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *bundlePath = [bundle pathForResource:@"3.5.0" ofType:@"xcappdata"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:NULL]) {
		XCTFail(@"App data doesn't exist: 3.5.0");
	}

	NSString *supportDirectoryPath = [bundlePath stringByAppendingString:@"/AppData/Library/Application Support/com.apptentive.feedback"];

	ApptentiveDataManager *dataManager = [[ApptentiveDataManager alloc] initWithModelName:@"ATDataModel" inBundle:bundle storagePath:supportDirectoryPath];
	NSManagedObjectContext *context = dataManager.managedObjectContext;

	NSArray *beforeResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	ApptentiveConversation *conversation = [[ApptentiveConversation alloc] initAndMigrate];

	[ApptentiveLegacySurveyResponse enqueueUnsentSurveyResponsesInContext:context forConversation:conversation];

	NSArray *afterResults = [context executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"] error:NULL];

	XCTAssertGreaterThan(afterResults.count, beforeResults.count);
}

- (void)testMigratingFrom5ToNew {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *conversationPath = [bundle pathForResource:@"conversation-5" ofType:@"archive"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:conversationPath isDirectory:NULL]) {
		XCTFail(@"Conversation data doesn't exist: conversation-5.archive");
	}

	ApptentiveConversation *conversation = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveConversation class] fromFile:conversationPath];

	XCTAssertNotNil(conversation);
	XCTAssertNotNil(conversation.appRelease);
	XCTAssertNotNil(conversation.SDK);
	XCTAssertNotNil(conversation.person);
	XCTAssertNotNil(conversation.device);
	XCTAssertNotNil(conversation.engagement);
}

- (void)testMigratingFrom4ToNew {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *conversationPath = [bundle pathForResource:@"conversation-4" ofType:@"archive"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:conversationPath isDirectory:NULL]) {
		XCTFail(@"Conversation data doesn't exist: conversation-4.archive");
	}

	ApptentiveConversation *conversation = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveConversation class] fromFile:conversationPath];

	XCTAssertNotNil(conversation);
	XCTAssertNotNil(conversation.appRelease);
	XCTAssertNotNil(conversation.SDK);
	XCTAssertNotNil(conversation.person);
	XCTAssertNotNil(conversation.device);
	XCTAssertNotNil(conversation.engagement);
}

- (void)testMigratingEngagmentManifestFrom5ToNew {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *manifestPath = [bundle pathForResource:@"manifest-v2" ofType:@"archive"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:manifestPath isDirectory:NULL]) {
		XCTFail(@"Conversation data doesn't exist: manifest-v2.archive");
	}

	ApptentiveEngagementManifest *manifest = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveEngagementManifest class] fromFile:manifestPath];

	XCTAssertNotNil(manifest);
	XCTAssertNotEqual(manifest.targets.invocations.count, 0);
	XCTAssertNotEqual(manifest.interactions.count, 0);
}

- (void)testMigratingMetadataFrom5ToNew {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *metadataPath = [bundle pathForResource:@"conversation-v1" ofType:@"meta"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:metadataPath isDirectory:NULL]) {
		XCTFail(@"Conversation data doesn't exist: conversation-v1.meta");
	}

	ApptentiveConversationMetadata *metadata = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveConversationMetadata class] fromFile:metadataPath];

	XCTAssertNotNil(metadata);
	XCTAssertNotEqual(metadata.items.count, 0);
}

- (void)testMigratingAppConfigurationFrom5ToNew {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *configurationPath = [bundle pathForResource:@"configuration-v1" ofType:@"archive"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:configurationPath isDirectory:NULL]) {
		XCTFail(@"Conversation data doesn't exist: configuration-v1.archive");
	}

	ApptentiveAppConfiguration *configuration = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveAppConfiguration class] fromFile:configurationPath];

	XCTAssertNotNil(configuration);
}

@end
