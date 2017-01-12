//
//  ApptentiveSession.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSession.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import "ApptentiveMutablePerson.h"
#import "ApptentiveMutableDevice.h"

static NSString * const AppReleaseKey = @"appRelease";
static NSString * const SDKKey = @"SDK";
static NSString * const PersonKey = @"person";
static NSString * const DeviceKey = @"device";
static NSString * const EngagementKey = @"engagement";
static NSString * const APIKeyKey = @"APIKey";
static NSString * const TokenKey = @"token";
static NSString * const LastMessageIDKey = @"lastMessageID";
static NSString * const UserInfoKey = @"userInfo";

@implementation ApptentiveSession

@synthesize token = _token;

- (instancetype)init {
	NSAssert(NO, @"Must call -initWithAPIKey:");
	return nil;
}

- (instancetype)initWithAPIKey:(NSString *)APIKey {
	self = [super init];
	if (self) {
		_appRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
		_SDK = [[ApptentiveSDK alloc] initWithCurrentSDK];
		_person = [[ApptentivePerson alloc] init];
		_device = [[ApptentiveDevice alloc] initWithCurrentDevice];
		_engagement = [[ApptentiveEngagement alloc] init];
		_userInfo = [[NSMutableDictionary alloc] init];
		_APIKey = APIKey;
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		_appRelease = [coder decodeObjectOfClass:[ApptentiveAppRelease class] forKey:AppReleaseKey];
		_SDK = [coder decodeObjectOfClass:[ApptentiveSDK class] forKey:SDKKey];
		_person = [coder decodeObjectOfClass:[ApptentivePerson class] forKey:PersonKey];
		_device = [coder decodeObjectOfClass:[ApptentiveDevice class] forKey:DeviceKey];
		_engagement = [coder decodeObjectOfClass:[ApptentiveEngagement class] forKey:EngagementKey];
		_APIKey = [coder decodeObjectOfClass:[NSString class] forKey:APIKeyKey];
		_token = [coder decodeObjectOfClass:[NSString class] forKey:TokenKey];
		_lastMessageID = [coder decodeObjectOfClass:[NSString class] forKey:LastMessageIDKey];
		_userInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:UserInfoKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:self.appRelease forKey:AppReleaseKey];
	[coder encodeObject:self.SDK forKey:SDKKey];
	[coder encodeObject:self.person forKey:PersonKey];
	[coder encodeObject:self.device forKey:DeviceKey];
	[coder encodeObject:self.engagement forKey:EngagementKey];
	[coder encodeObject:self.APIKey forKey:APIKeyKey];
	[coder encodeObject:self.token forKey:TokenKey];
	[coder encodeObject:self.lastMessageID forKey:LastMessageIDKey];
	[coder encodeObject:self.userInfo forKey:UserInfoKey];
}

- (void)setToken:(NSString *)token personID:(NSString *)personID deviceID:(NSString *)deviceID {
	_token = token;
	self.person.identifier = personID;
	self.device.identifier = deviceID;
}

- (void)checkForDiffs {
	ApptentiveAppRelease *currentAppRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
	if (self.appRelease.overridingStyles) {
		[currentAppRelease setOverridingStyles];
	}

	ApptentiveSDK *currentSDK = [[ApptentiveSDK alloc] initWithCurrentSDK];

	[self updateDevice:^(ApptentiveMutableDevice *device){}];

	BOOL conversationNeedsUpdate = NO;

	NSDictionary *appReleaseDiffs = [ApptentiveUtilities diffDictionary:currentAppRelease.JSONDictionary againstDictionary:self.appRelease.JSONDictionary];

	if (appReleaseDiffs.count > 0) {
		conversationNeedsUpdate = YES;

		if (![currentAppRelease.version isEqualToVersion:self.appRelease.version]) {
			[self.appRelease resetVersion];
			[self.engagement resetVersion];
		}

		if (![currentAppRelease.build isEqualToVersion:self.appRelease.build]) {
			[self.appRelease resetBuild];
			[self.engagement resetBuild];
		}

		_appRelease = currentAppRelease;
	}

	NSDictionary *SDKDiffs = [ApptentiveUtilities diffDictionary:currentSDK.JSONDictionary againstDictionary:self.SDK.JSONDictionary];

	if (SDKDiffs.count > 0) {
		conversationNeedsUpdate = YES;

		_SDK = currentSDK;
	}

	if (conversationNeedsUpdate) {
		[self.delegate session:self conversationDidChange:self.conversationUpdateJSON];
	}
}

- (void)updatePerson:(void (^)(ApptentiveMutablePerson *))personUpdateBlock {
	if (!personUpdateBlock) {
		return;
	}

	ApptentiveMutablePerson *mutablePerson = [[ApptentiveMutablePerson alloc] initWithPerson:self.person];

	personUpdateBlock(mutablePerson);

	ApptentivePerson *newPerson = [[ApptentivePerson alloc] initWithMutablePerson:mutablePerson];

	NSDictionary *personDiffs = [ApptentiveUtilities diffDictionary:newPerson.JSONDictionary againstDictionary:self.person.JSONDictionary];

	if (personDiffs.count > 0) {
		_person = newPerson;

		[self.delegate session:self personDidChange:@{ @"person": personDiffs }];
	}
}

- (void)updateDevice:(void (^)(ApptentiveMutableDevice *))deviceUpdateBlock {
	if (!deviceUpdateBlock) {
		return;
	}

	ApptentiveMutableDevice *mutableDevice = [[ApptentiveMutableDevice alloc] initWithDevice:self.device];

	deviceUpdateBlock(mutableDevice);

	ApptentiveDevice *newDevice = [[ApptentiveDevice alloc] initWithMutableDevice:mutableDevice];

	NSDictionary *deviceDiffs = [ApptentiveUtilities diffDictionary:newDevice.JSONDictionary againstDictionary:self.device.JSONDictionary];

	if (deviceDiffs.count > 0) {
		_device = newDevice;

		[self.delegate session:self deviceDidChange:@{ @"device": deviceDiffs }];
	}
}

- (void)didOverrideStyles {
	if (!self.appRelease.overridingStyles) {
		[self.appRelease setOverridingStyles];

		[self checkForDiffs];
	}
}

- (void)didDownloadMessagesUpTo:(NSString *)lastMessageID {
	_lastMessageID = lastMessageID;
}

- (NSDate *)currentTime {
	return [NSDate date];
}

- (NSDictionary *)conversationCreationJSON {
	return @{
		@"app_release": self.appRelease.JSONDictionary,
		@"sdk": self.SDK.JSONDictionary,
		@"person": self.person.JSONDictionary,
		@"device": self.device.JSONDictionary
	};
}

- (NSDictionary *)conversationUpdateJSON {
	return @{
		@"app_release": self.appRelease.JSONDictionary,
		@"sdk": self.SDK.JSONDictionary
	};
}

- (instancetype)initAndMigrate {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInstallDateKey"]) {
		return nil;
	}

	self = [super init];

	if (self) {
		_appRelease = [[ApptentiveAppRelease alloc] initAndMigrate];
		_SDK = [[ApptentiveSDK alloc] initAndMigrate];
		_person = [[ApptentivePerson alloc] initAndMigrate];
		_device = [[ApptentiveDevice alloc] initAndMigrate];
		_engagement = [[ApptentiveEngagement alloc] initAndMigrate];

		NSData *legacyConversationData = [[NSUserDefaults standardUserDefaults] dataForKey:@"ATCurrentConversationPreferenceKey"];
		ApptentiveLegacyConversation *legacyConversation = (ApptentiveLegacyConversation *)[NSKeyedUnarchiver unarchiveObjectWithData:legacyConversationData];
		_token = legacyConversation.token;
		_person.identifier = legacyConversation.personID;
		_device.identifier = legacyConversation.deviceID;

		NSString *ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
		NSString *ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";

		[_userInfo setObject:[[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] forKey:ATMessageCenterDraftMessageKey];
		[_userInfo setObject:@([[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidSkipProfileKey]) forKey:ATMessageCenterDidSkipProfileKey];
	}

	return self;
}

+ (void)deleteMigratedData {
	[ApptentiveAppRelease deleteMigratedData];
	[ApptentiveSDK deleteMigratedData];
	[ApptentivePerson deleteMigratedData];
	[ApptentiveDevice deleteMigratedData];
	[ApptentiveEngagement deleteMigratedData];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"ATCurrentConversationPreferenceKey"];
}

@end

@implementation ApptentiveLegacyConversation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATConversation"];
	[NSKeyedUnarchiver setClass:self forClassName:@"ApptentiveConversation"];
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_token = [coder decodeObjectForKey:@"token"];
		_personID = [coder decodeObjectForKey:@"personID"];
		_deviceID = [coder decodeObjectForKey:@"deviceID"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

@end
