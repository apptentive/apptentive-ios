//
//  ApptentiveConversation.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveConversationMetadataItem.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const AppReleaseKey = @"appRelease";
static NSString *const SDKKey = @"SDK";
static NSString *const PersonKey = @"person";
static NSString *const DeviceKey = @"device";
static NSString *const EngagementKey = @"engagement";
static NSString *const APIKeyKey = @"APIKey";
static NSString *const TokenKey = @"token";
static NSString *const LegacyTokenKey = @"legacyToken";
static NSString *const LastMessageIDKey = @"lastMessageID";
static NSString *const MutableUserInfoKey = @"mutableUserInfo";
static NSString *const ArchiveVersionKey = @"archiveVersion";
static NSString *const IdentifierKey = @"identifier";
static NSString *const LocalIdentifierKey = @"localIdentifier";
static NSString *const DirectoryNameKey = @"directoryName";
static NSString *const LastSentDeviceKey = @"lastSentDevice";
static NSString *const LastSentPersonKey = @"lastSentPerson";


// Legacy keys
static NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";
static NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
static NSString *const ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";

NSString *NSStringFromApptentiveConversationState(ApptentiveConversationState state) {
	switch (state) {
		case ApptentiveConversationStateUndefined:
			return @"undefined";
		case ApptentiveConversationStateAnonymousPending:
			return @"anonymous pending";
		case ApptentiveConversationStateLegacyPending:
			return @"legacy pending";
		case ApptentiveConversationStateAnonymous:
			return @"anonymous";
		case ApptentiveConversationStateLoggedIn:
			return @"logged-in";
		case ApptentiveConversationStateLoggedOut:
			return @"logged-out";
	}

	return @"unknown";
}


@interface ApptentiveConversation ()

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *legacyToken;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSData *encryptionKey;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) ApptentiveAppRelease *appRelease;
@property (strong, nonatomic) ApptentiveSDK *SDK;
@property (strong, nonatomic) ApptentivePerson *person;
@property (strong, nonatomic) ApptentiveDevice *device;
@property (strong, nonatomic) ApptentiveEngagement *engagement;
@property (strong, nonatomic) NSMutableDictionary *mutableUserInfo;
@property (strong, nonatomic) NSDictionary *lastSentPerson;
@property (strong, nonatomic) NSDictionary *lastSentDevice;
@property (strong, nonatomic) NSString *directoryName;
@property (strong, nullable, nonatomic) NSString *sessionIdentifier;

@end


@implementation ApptentiveConversation

- (instancetype)initWithState:(ApptentiveConversationState)state {
	self = [super init];
	if (self) {
		_localIdentifier = [[NSUUID UUID] UUIDString];
		_state = state;
		_appRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
		_SDK = [[ApptentiveSDK alloc] initWithCurrentSDK];
		_person = [[ApptentivePerson alloc] init];
		_device = [[ApptentiveDevice alloc] initWithCurrentDevice];
		_engagement = [[ApptentiveEngagement alloc] init];
		_mutableUserInfo = [[NSMutableDictionary alloc] init];

		_directoryName = [NSUUID UUID].UUIDString;

		_lastSentDevice = @{};
		_lastSentPerson = @{};
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		_appRelease = [coder decodeObjectOfClass:[ApptentiveAppRelease class] forKey:AppReleaseKey];
		_SDK = [coder decodeObjectOfClass:[ApptentiveSDK class] forKey:SDKKey];
		_person = [coder decodeObjectOfClass:[ApptentivePerson class] forKey:PersonKey];
		_device = [coder decodeObjectOfClass:[ApptentiveDevice class] forKey:DeviceKey];
		_engagement = [coder decodeObjectOfClass:[ApptentiveEngagement class] forKey:EngagementKey];
		_token = [coder decodeObjectOfClass:[NSString class] forKey:TokenKey];
		_legacyToken = [coder decodeObjectOfClass:[NSString class] forKey:LegacyTokenKey];
		_lastMessageID = [coder decodeObjectOfClass:[NSString class] forKey:LastMessageIDKey];
		_mutableUserInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:MutableUserInfoKey];
		_identifier = [coder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
		_localIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:LocalIdentifierKey] ?: [[NSUUID UUID] UUIDString];
		_directoryName = [coder decodeObjectOfClass:[NSString class] forKey:DirectoryNameKey];
		_lastSentDevice = [coder decodeObjectOfClass:[NSDictionary class] forKey:LastSentDeviceKey];
		_lastSentPerson = [coder decodeObjectOfClass:[NSDictionary class] forKey:LastSentPersonKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.appRelease forKey:AppReleaseKey];
	[coder encodeObject:self.SDK forKey:SDKKey];
	[coder encodeObject:self.person forKey:PersonKey];
	[coder encodeObject:self.device forKey:DeviceKey];
	[coder encodeObject:self.engagement forKey:EngagementKey];
	[coder encodeObject:self.token forKey:TokenKey];
	[coder encodeObject:self.legacyToken forKey:LegacyTokenKey];
	[coder encodeObject:self.lastMessageID forKey:LastMessageIDKey];
	[coder encodeObject:self.mutableUserInfo forKey:MutableUserInfoKey];
	[coder encodeObject:self.identifier forKey:IdentifierKey];
	[coder encodeObject:self.localIdentifier forKey:LocalIdentifierKey];
	[coder encodeObject:self.directoryName forKey:DirectoryNameKey];
	[coder encodeObject:self.lastSentDevice forKey:LastSentDeviceKey];
	[coder encodeObject:self.lastSentPerson forKey:LastSentPersonKey];
	[coder encodeObject:@1 forKey:ArchiveVersionKey];
}

- (void)checkForDiffs {
	ApptentiveAppRelease *currentAppRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
	[currentAppRelease copyNonholonomicValuesFrom:self.appRelease];

  ApptentiveSDK *currentSDK = [[ApptentiveSDK alloc] initWithCurrentSDK];

	BOOL conversationNeedsUpdate = NO;

	NSDictionary *appReleaseDiffs = [ApptentiveUtilities diffDictionary:currentAppRelease.JSONDictionary againstDictionary:self.appRelease.JSONDictionary];

	if (appReleaseDiffs.count > 0) {
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"One or more App release fields have changed: %@", ApptentiveHideKeysIfSanitized(appReleaseDiffs, [ApptentiveAppRelease sensitiveKeys]));
		conversationNeedsUpdate = YES;

		if (![currentAppRelease.version isEqualToVersion:self.appRelease.version]) {
			[currentAppRelease resetVersion];
			[self.engagement resetVersion];
		}

		if (![currentAppRelease.build isEqualToVersion:self.appRelease.build]) {
			[currentAppRelease resetBuild];
			[self.engagement resetBuild];
		}

		_appRelease = currentAppRelease;
	}

	NSDictionary *SDKDiffs = [ApptentiveUtilities diffDictionary:currentSDK.JSONDictionary againstDictionary:self.SDK.JSONDictionary];

	if (SDKDiffs.count > 0) {
		ApptentiveLogDebug(ApptentiveLogTagConversation, @"One or more Apptentive SDK fields have changed: %@", ApptentiveHideKeysIfSanitized(SDKDiffs, [ApptentiveSDK sensitiveKeys]));
		
		conversationNeedsUpdate = YES;

		_SDK = currentSDK;
	}

	if (conversationNeedsUpdate) {
		[self notifyConversationChanged];

		if ([_delegate respondsToSelector:@selector(conversationAppReleaseOrSDKDidChange:)]) {
			[_delegate conversationAppReleaseOrSDKDidChange:self];
		}
	}

	// See if any of the non-custom device attributes have changed
	[self checkForDeviceDiffs];
}

- (void)checkForDeviceDiffs {
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Checking for changes to the device fields...");

	[self.device updateWithCurrentDeviceValues];

	NSDictionary *deviceDiffs = [ApptentiveUtilities diffDictionary:self.device.JSONDictionary againstDictionary:self.lastSentDevice];

	if (deviceDiffs.count > 0) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"One or more device fields have changed: %@", ApptentiveHideKeysIfSanitized(deviceDiffs, [ApptentiveDevice sensitiveKeys]));

		[self.delegate conversation:self deviceDidChange:deviceDiffs];
		[self updateLastSentDevice];
	}
}

- (void)updateLastSentDevice {
	self.lastSentDevice = self.device.JSONDictionary;
}

- (void)checkForPersonDiffs {
	ApptentiveLogDebug(ApptentiveLogTagConversation, @"Checking for changes to the person fields...");

	NSDictionary *personDiffs = [ApptentiveUtilities diffDictionary:self.person.JSONDictionary againstDictionary:self.lastSentPerson];

	if (personDiffs.count > 0) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"One or more person fields have changed: %@", ApptentiveHideKeysIfSanitized(personDiffs, [ApptentivePerson sensitiveKeys]));

		[self.delegate conversation:self personDidChange:personDiffs];
		self.lastSentPerson = self.person.JSONDictionary;
	}
}

- (void)notifyConversationChanged {
	if ([_delegate respondsToSelector:@selector(conversationDidChange:)]) {
		[_delegate conversationDidChange:self];
	}
}

- (void)notifyConversationEngagementDidChange {
	[self notifyConversationChanged];

	if ([_delegate respondsToSelector:@selector(conversationEngagementDidChange:)]) {
		[_delegate conversationEngagementDidChange:self];
	}
}

- (void)warmCodePoint:(NSString *)codePoint {
	[self.engagement warmCodePoint:codePoint];
}

- (void)engageCodePoint:(NSString *)codePoint {
	[self.engagement engageCodePoint:codePoint];

	[self notifyConversationEngagementDidChange];
}

- (void)warmInteraction:(NSString *)codePoint {
	[self.engagement warmInteraction:codePoint];
}

- (void)engageInteraction:(NSString *)interactionIdentifier {
	[self.engagement engageInteraction:interactionIdentifier];

	[self notifyConversationEngagementDidChange];
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

- (instancetype)initAndMigrate {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInstallDateKey"]) {
		return nil;
	}

	self = [super init];

	if (self) {
		_state = ApptentiveConversationStateLegacyPending;
		_appRelease = [[ApptentiveAppRelease alloc] initAndMigrate];
		_SDK = [[ApptentiveSDK alloc] initAndMigrate];
		_person = [[ApptentivePerson alloc] initAndMigrate];
		_device = [[ApptentiveDevice alloc] initAndMigrate];
		_engagement = [[ApptentiveEngagement alloc] initAndMigrate];

		_directoryName = [NSUUID UUID].UUIDString;
		_localIdentifier = [NSUUID UUID].UUIDString;

		NSData *legacyConversationData = [[NSUserDefaults standardUserDefaults] dataForKey:ATCurrentConversationPreferenceKey];

		if (legacyConversationData != nil) {
			[NSKeyedUnarchiver setClass:[ApptentiveLegacyConversation class] forClassName:@"ApptentiveConversation"];
			[NSKeyedUnarchiver setClass:[ApptentiveLegacyConversation class] forClassName:@"ATConversation"];

			ApptentiveLegacyConversation *legacyConversation = (ApptentiveLegacyConversation *)[NSKeyedUnarchiver unarchiveObjectWithData:legacyConversationData];

			[NSKeyedUnarchiver setClass:[self class] forClassName:@"ApptentiveConversation"];

			// we only need a legacy token here: jwt-token and conversation id would be fetched later
			_legacyToken = legacyConversation.token;
			_person.identifier = legacyConversation.personID;
			_device.identifier = legacyConversation.deviceID;
		}

		_mutableUserInfo = [NSMutableDictionary dictionary];

		NSString *draftMessage = [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey];

		if (draftMessage) {
			[_mutableUserInfo setObject:draftMessage forKey:ATMessageCenterDraftMessageKey];
		}

		[_mutableUserInfo setObject:@([[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidSkipProfileKey]) forKey:ATMessageCenterDidSkipProfileKey];

		// Migrate last sent device if available
		_lastSentDevice = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey][@"device"] ?: @{};

		// Migrate last sent person if available
		NSData *lastSentPersondata = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

		if (lastSentPersondata != nil) {
			NSDictionary *person = [NSKeyedUnarchiver unarchiveObjectWithData:lastSentPersondata];
			if ([person isKindOfClass:[NSDictionary class]]) {
				_lastSentPerson = person[@"person"];
			} else {
				_lastSentPerson = @{};
			}
		} else {
			_lastSentPerson = @{};
		}
	}

	return self;
}

- (void)updateWithCurrentValues {
	_SDK = [[ApptentiveSDK alloc] initWithCurrentSDK];

	ApptentiveAppRelease *currentAppRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
	[currentAppRelease copyNonholonomicValuesFrom:self.appRelease];
	_appRelease = currentAppRelease;

	_state = ApptentiveConversationStateAnonymousPending;

	[self.device updateWithCurrentDeviceValues];
}

- (BOOL)hasActiveState {
	return _state == ApptentiveConversationStateAnonymous || _state == ApptentiveConversationStateLoggedIn;
}

- (BOOL)isConsistent {
	if (self.state == ApptentiveConversationStateUndefined) {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation state is undefined.");
		return NO;
	}
	
	if (self.directoryName.length == 0) {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation directory name is empty.");
		return NO;
	}
	
	if (self.state == ApptentiveConversationStateAnonymous || self.state == ApptentiveConversationStateLoggedIn) {
		if (self.identifier.length == 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation identifier is nil or empty for state %@.", NSStringFromApptentiveConversationState(self.state));
			
			return NO;
		}
		
		if (self.token.length == 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation auth token is nil or empty for state %@.", NSStringFromApptentiveConversationState(self.state));
			
			return NO;
		}
	}
	
	if (self.state == ApptentiveConversationStateLoggedIn) {
		if (self.userId.length == 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation userId is nil or empty for logged-in conversation.");
			return NO;
		}
		
		if (self.encryptionKey.length == 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Conversation encryption key is nil or empty for logged-in conversation.");
			return NO;
		}
	}

	if (self.state == ApptentiveConversationStateAnonymousPending || self.state == ApptentiveConversationStateLegacyPending) {
		if (self.identifier.length > 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Pending conversation has identifier.");
			return NO;
		}

		if (self.token.length > 0) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Pending conversation has token.");
			return NO;
		}
	}
	
	return YES;
}

- (void)startSession {
	_sessionIdentifier = [NSUUID.UUID.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

- (void)endSession {
	_sessionIdentifier = nil;
}

+ (void)deleteMigratedData {
	[ApptentiveAppRelease deleteMigratedData];
	[ApptentiveSDK deleteMigratedData];
	[ApptentivePerson deleteMigratedData];
	[ApptentiveDevice deleteMigratedData];
	[ApptentiveEngagement deleteMigratedData];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATCurrentConversationPreferenceKey];
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithDictionary:self.mutableUserInfo];
}

- (void)setUserInfo:(NSObject *)object forKey:(NSString *)key {
	if (object != nil && key != nil) {
		[self.mutableUserInfo setObject:object forKey:key];

		[self notifyConversationChanged];

		if ([_delegate respondsToSelector:@selector(conversationUserInfoDidChange:)]) {
			[_delegate conversationUserInfoDidChange:self];
		}
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to set user info with nil key and/or value.");
	}
}

- (void)removeUserInfoForKey:(NSString *)key {
	if (key != nil) {
		[self.mutableUserInfo removeObjectForKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to set user info with nil key and/or value.");
	}
}

#pragma mark - Mutability

- (id)mutableCopy {
	ApptentiveMutableConversation *result = [[ApptentiveMutableConversation alloc] init];
	result.state = self.state;
	result.token = self.token;
	result.legacyToken = self.legacyToken;
	result.userId = self.userId;
	result.encryptionKey = self.encryptionKey;
	result.appRelease = self.appRelease;
	result.SDK = self.SDK;
	result.person = self.person;
	result.device = self.device;
	result.engagement = self.engagement;
	result.mutableUserInfo = self.mutableUserInfo;
	result.lastSentPerson = self.lastSentPerson;
	result.lastSentDevice = self.lastSentDevice;
	result.identifier = self.identifier;
	result.localIdentifier = self.localIdentifier;
	result.lastMessageID = self.lastMessageID;
	result.delegate = self.delegate;
	result.directoryName = self.directoryName;
	result.sessionIdentifier = self.sessionIdentifier;
	return result;
}


@end


@implementation ApptentiveLegacyConversation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATConversation"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
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


@interface ApptentiveMutableConversation ()

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *localIdentifier;
@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) NSString *directoryName;

@end


@implementation ApptentiveMutableConversation

@dynamic mutableUserInfo;
@dynamic lastSentPerson;
@dynamic lastSentDevice;
@dynamic state;
@dynamic appRelease;
@dynamic SDK;
@dynamic person;
@dynamic device;
@dynamic engagement;
@dynamic token;
@dynamic identifier;
@dynamic localIdentifier;
@dynamic legacyToken;
@dynamic userId;
@dynamic encryptionKey;
@dynamic lastMessageID;
@dynamic directoryName;
@dynamic sessionIdentifier;

- (void)setToken:(NSString *)token conversationID:(NSString *)conversationID personID:(NSString *)personID deviceID:(NSString *)deviceID {
	[self setConversationIdentifier:conversationID JWT:token];
	self.person.identifier = personID;
	self.device.identifier = deviceID;
}

- (void)setConversationIdentifier:(NSString *)identifier JWT:(NSString *)JWT {
	self.identifier = identifier;
	self.token = JWT;
}

@end

@implementation ApptentiveConversation (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	if ([path hasPrefix:@"code_point/"] || [path hasPrefix:@"interactions/"]) {
		return [self.engagement valueForFieldWithPath:path];
	} else if ([path hasPrefix:@"is_update/"] || [path hasPrefix:@"time_at_install/"]) {
		return [self.appRelease valueForFieldWithPath:path];
	} else if ([path isEqualToString:@"current_time"]) {
		return self.currentTime;
	} else {
		// Fan out to properties
		NSArray *parts = [path componentsSeparatedByString:@"/"];
		NSMutableArray *trimmedParts = [NSMutableArray arrayWithCapacity:parts.count];

		for (NSString *part in parts) {
			[trimmedParts addObject:[part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}

		NSString *first = trimmedParts.firstObject;
		NSString *rest = [[trimmedParts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@"/"];

		if ([first isEqualToString:@"application"]) {
			return [self.appRelease valueForFieldWithPath:rest];
		} else if ([first isEqualToString:@"sdk"]) {
			return [self.SDK valueForFieldWithPath:rest];
		} else if ([first isEqualToString:@"person"]) {
			return [self.person valueForFieldWithPath:rest];
		} else if ([first isEqualToString:@"device"]) {
			return [self.device valueForFieldWithPath:rest];
		}
	}

	ApptentiveLogError(@"Unrecognized field name “%@”", path);
	return nil;
}

- (NSString *)descriptionForFieldWithPath:(id)path {
	if ([path hasPrefix:@"code_point/"] || [path hasPrefix:@"interactions/"]) {
		return [self.engagement descriptionForFieldWithPath:path];
	} else if ([path hasPrefix:@"is_update/"] || [path hasPrefix:@"time_at_install/"]) {
		return [self.appRelease descriptionForFieldWithPath:path];
	} else if ([path isEqualToString:@"current_time"]) {
		return @"current time";
	} else {
		// Fan out to properties
		NSArray *parts = [path componentsSeparatedByString:@"/"];
		NSMutableArray *trimmedParts = [NSMutableArray arrayWithCapacity:parts.count];

		for (NSString *part in parts) {
			[trimmedParts addObject:[part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		}

		NSString *first = trimmedParts.firstObject;
		NSString *rest = [[trimmedParts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@"/"];

		if ([first isEqualToString:@"application"]) {
			return [self.appRelease descriptionForFieldWithPath:rest];
		} else if ([first isEqualToString:@"sdk"]) {
			return [self.SDK descriptionForFieldWithPath:rest];
		} else if ([first isEqualToString:@"person"]) {
			return [self.person descriptionForFieldWithPath:rest];
		} else if ([first isEqualToString:@"device"]) {
			return [self.device descriptionForFieldWithPath:rest];
		}
	}

	return [NSString stringWithFormat:@"Unrecognized field %@", path];
}

@end

NS_ASSUME_NONNULL_END
