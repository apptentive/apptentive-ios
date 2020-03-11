//
//  ApptentiveEngagement.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const InteractionsKey = @"interactions";
static NSString *const CodePointsKey = @"codePoints";
static NSString *const VersionKey = @"version";

// Legacy keys
static NSString *const ATEngagementCodePointsInvokesTotalKey = @"ATEngagementCodePointsInvokesTotalKey";
static NSString *const ATEngagementCodePointsInvokesVersionKey = @"ATEngagementCodePointsInvokesVersionKey";
static NSString *const ATEngagementCodePointsInvokesBuildKey = @"ATEngagementCodePointsInvokesBuildKey";
static NSString *const ATEngagementCodePointsInvokesLastDateKey = @"ATEngagementCodePointsInvokesLastDateKey";
static NSString *const ATEngagementInteractionsInvokesTotalKey = @"ATEngagementInteractionsInvokesTotalKey";
static NSString *const ATEngagementInteractionsInvokesVersionKey = @"ATEngagementInteractionsInvokesVersionKey";
static NSString *const ATEngagementInteractionsInvokesBuildKey = @"ATEngagementInteractionsInvokesBuildKey";
static NSString *const ATEngagementInteractionsInvokesLastDateKey = @"ATEngagementInteractionsInvokesLastDateKey";
static NSInteger const CurrentVersion = 2;

@interface ApptentiveEngagement ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, ApptentiveCount *> *mutableInteractions;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ApptentiveCount *> *mutableCodePoints;
@property (assign, nonatomic) NSInteger version;

@end

@implementation ApptentiveEngagement

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_mutableInteractions = [NSMutableDictionary dictionary];
		_mutableCodePoints = [NSMutableDictionary dictionary];
		_version = CurrentVersion;
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		NSSet *classes = [NSSet setWithArray:@[[NSMutableDictionary class], [ApptentiveCount class]]];

		_mutableInteractions = [coder decodeObjectOfClasses:classes forKey:InteractionsKey];
		_mutableCodePoints = [coder decodeObjectOfClasses:classes forKey:CodePointsKey];
		if ([coder containsValueForKey:VersionKey]) {
			_version = [coder decodeIntegerForKey:VersionKey];
		} else {
			_version = 1;
		}

		@try {
			if (_version != CurrentVersion) {
				[self migrateFrom:_version to:CurrentVersion];
			}
		} @catch(NSException *exception) {
			ApptentiveLogError(ApptentiveLogTagConversation, @"Caught exception %e when migrating engagement data. Starting over.", exception);
			return [self init];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.mutableInteractions forKey:InteractionsKey];
	[coder encodeObject:self.mutableCodePoints forKey:CodePointsKey];
	[coder encodeInteger:self.version forKey:VersionKey];
}

// This migrates pre-4.0 data stored in NSUserDefaults to 4.0 and later versions stored in NSCoding archive
- (instancetype)initAndMigrate {
	self = [self init];

	if (self) {
		NSDictionary *codePointsInvokesTotal = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementCodePointsInvokesTotalKey];
		NSDictionary *codePointsInvokesVersion = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementCodePointsInvokesVersionKey];
		NSDictionary *codePointsInvokesBuild = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementCodePointsInvokesBuildKey];
		NSDictionary *codePointsInvokesLastDate = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementCodePointsInvokesLastDateKey];

		for (NSString *key in codePointsInvokesTotal) {
			_mutableCodePoints[key] = [[ApptentiveCount alloc] initWithTotalCount:[codePointsInvokesTotal[key] integerValue] versionCount:[codePointsInvokesVersion[key] integerValue] buildCount:[codePointsInvokesBuild[key] integerValue] lastInvoked:codePointsInvokesLastDate[key]];
		}

		NSDictionary *interactionsInvokesTotal = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementInteractionsInvokesTotalKey];
		NSDictionary *interactionsInvokesVersion = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementInteractionsInvokesVersionKey];
		NSDictionary *interactionsInvokesBuild = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementInteractionsInvokesBuildKey];
		NSDictionary *interactionsInvokesLastDate = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATEngagementInteractionsInvokesLastDateKey];

		for (NSString *key in interactionsInvokesTotal) {
			_mutableInteractions[key] = [[ApptentiveCount alloc] initWithTotalCount:[interactionsInvokesTotal[key] integerValue] versionCount:[interactionsInvokesVersion[key] integerValue] buildCount:[interactionsInvokesBuild[key] integerValue] lastInvoked:interactionsInvokesLastDate[key]];
		}
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCodePointsInvokesTotalKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCodePointsInvokesVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCodePointsInvokesBuildKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCodePointsInvokesLastDateKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsInvokesTotalKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsInvokesVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsInvokesBuildKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsInvokesLastDateKey];
}

- (void)migrateFrom:(NSInteger)fromVersion to:(NSInteger)toVersion {
	if (fromVersion == 1 && toVersion == 2) {
		if ([self escapeUnescapedKeysInCodePoints]) {
			_version = toVersion;
		}
	}
}

- (BOOL)escapeUnescapedKeysInCodePoints {
	NSMutableArray *codePointsToMerge = [NSMutableArray array];

	for (NSString *key in self.codePoints) {
		NSString *escapedKey = [[self class] escapedKeyForKey:key];

		if (escapedKey == nil) {
			continue;
		}

		[codePointsToMerge addObject:@[key, escapedKey]];
	}

	NSMutableDictionary *escapedCodePoints = [NSMutableDictionary dictionaryWithDictionary:self.codePoints];
	for (NSArray *keys in codePointsToMerge) {
		NSString *key = keys[0];
		NSString *escapedKey = keys[1];

		ApptentiveCount *oldCount = [self.codePoints objectForKey:key];
		ApptentiveCount *newCount = [self.codePoints objectForKey:escapedKey];
		escapedCodePoints[escapedKey] = [ApptentiveCount mergeOldCount:oldCount withNewCount:newCount];
		[escapedCodePoints removeObjectForKey:key];
	}

	_mutableCodePoints = escapedCodePoints;

	return YES;
}

+ (nullable NSString *)escapedKeyForKey:(NSString *)key {
	NSArray *keyParts = [key componentsSeparatedByString:@"#"];

	if (keyParts.count < 3) {
		ApptentiveLogWarning(ApptentiveLogTagConversation, @"Unable to migrate unencoded code point %@", key);
		return nil;
	}

	NSString *vendor = keyParts[0];
	NSString *interaction = keyParts[1];
	// If the event name had pound signs in it, then there will be two or more parts starting at index 2.
	// We join those parts with a pound sign, which conveniently no-ops in the case of a single part.
	NSString *event = [[keyParts subarrayWithRange:NSMakeRange(2, keyParts.count - 2)] componentsJoinedByString:@"#"];

	if ([[self class] eventNeedsEscaping:event]) {
		return [ApptentiveBackend codePointForVendor:vendor interactionType:interaction event:event];
	} else {
		return nil;
	}
}

// Use some heuristics to see if the event name needs to be escaped and hasn't already been escaped
+ (BOOL)eventNeedsEscaping:(NSString *)event {
	// Slashes definitey need escaping
	BOOL slashesFound = [event containsString:@"/"];
	// Pound signs definitely need escaping
	BOOL poundSignsFound = [event containsString:@"#"];
	// Third-party percent signs would also need escaping, but there aren't instances of those in our events database, so we good.

	return slashesFound || poundSignsFound;
}

- (NSDictionary<NSString *, ApptentiveCount *> *)interactions {
	return [NSDictionary dictionaryWithDictionary:self.mutableInteractions];
}

- (NSDictionary<NSString *, ApptentiveCount *> *)codePoints {
	return [NSDictionary dictionaryWithDictionary:self.mutableCodePoints];
}

- (void)warmCodePoint:(NSString *)codePoint {
	if (self.mutableCodePoints[codePoint] == nil) {
		self.mutableCodePoints[codePoint] = [[ApptentiveCount alloc] init];
	}
}

- (void)warmInteraction:(NSString *)interaction {
	if (self.mutableInteractions[interaction] == nil) {
		self.mutableInteractions[interaction] = [[ApptentiveCount alloc] init];
	}
}

- (void)engageCodePoint:(NSString *)codePoint {
	[self warmCodePoint:codePoint];
	[self.mutableCodePoints[codePoint] invoke];
}

- (void)engageInteraction:(NSString *)interaction {
	[self warmInteraction:interaction];
	[self.mutableInteractions[interaction] invoke];
}

- (void)resetVersion {
	for (ApptentiveCount *count in self.codePoints.allValues) {
		[count resetVersion];
	}

	for (ApptentiveCount *count in self.interactions.allValues) {
		[count resetVersion];
	}
}

- (void)resetBuild {
	for (ApptentiveCount *count in self.codePoints.allValues) {
		[count resetBuild];
	}

	for (ApptentiveCount *count in self.interactions.allValues) {
		[count resetBuild];
	}
}

@end


@implementation ApptentiveEngagement (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"interactions": NSStringFromSelector(@selector(interactions)),
		@"code_points": NSStringFromSelector(@selector(codePoints))
	};
}

@end

@implementation ApptentiveEngagement (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	NSArray *parts = [path componentsSeparatedByString:@"/"];

	if (parts.count != 4) {
		ApptentiveLogError(@"Invalid field name “%@”", path);
		return nil;
	}

	NSString *key = parts[1];

	if ([parts.firstObject isEqualToString:@"code_point"]) {
		[self warmCodePoint:key];
	} else if ([parts.firstObject isEqualToString:@"interactions"]) {
		[self warmInteraction:key];
	}

	NSDictionary *values = @{ @"code_point": self.codePoints, @"interactions": self.interactions };

	ApptentiveCount *count = [values[parts.firstObject] objectForKey:key];

	if (count == nil) {
		ApptentiveLogError(@"%@ “%@” not found", parts.firstObject, key);
		return nil;
	}

	return [count valueForFieldWithPath:[[parts subarrayWithRange:NSMakeRange(2, 2)] componentsJoinedByString:@"/"]];
}

- (NSString *)descriptionForFieldWithPath:(NSString *)path {
	NSArray *parts = [path componentsSeparatedByString:@"/"];

	if (parts.count != 4) {
		ApptentiveLogError(@"Invalid field name “%@”", path);
		return [NSString stringWithFormat:@"Unrecognized engagement field %@", path];
	}

	NSString *type = [parts[0] isEqualToString:@"code_point"] ? @"event" : @"interaction";
	NSString *target = parts[1];
	NSString *invokesOrTime = parts[2];
	NSString *scope = parts[3];

	if ([invokesOrTime isEqualToString:@"invokes"]) {
		if ([scope isEqualToString:@"total"]) {
			return [NSString stringWithFormat:@"number of invokes for %@ '%@'", type, target];
		} else if ([scope isEqualToString:@"cf_bundle_short_version_string"]) {
			// TODO: Could print out version here to match Android
			return [NSString stringWithFormat:@"number of invokes for %@ '%@' for current version", type, target];
		} else if ([scope isEqualToString:@"cf_bundle_version"]) {
			// TODO: Could print out build here to match Android
			return [NSString stringWithFormat:@"number of invokes for %@ '%@' for current build", type, target];
		}
	} else if ([invokesOrTime isEqualToString:@"last_invoked_at"] && [scope isEqualToString:@"total"]) {
		return [NSString stringWithFormat:@"last time %@ '%@' was invoked", type, target];
	}

	return [NSString stringWithFormat:@"Unrecognized engagement field %@", path];
}



@end

NS_ASSUME_NONNULL_END
