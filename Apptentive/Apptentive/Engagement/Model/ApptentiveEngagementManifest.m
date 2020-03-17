//
//  ApptentiveEngagementManifest.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementManifest.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveTargets.h"
#import "ApptentiveUnarchiver.h"
#import "ApptentiveInvocations.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const TargetsKey = @"targets";
static NSString *const InteractionsKey = @"interactions";
static NSString *const ExpiryKey = @"expiry";

// Legacy keys
static NSString *const ATEngagementCachedInteractionsExpirationPreferenceKey = @"ATEngagementCachedInteractionsExpirationPreferenceKey";
static NSString *const ATEngagementInteractionsSDKVersionKey = @"ATEngagementInteractionsSDKVersionKey";
static NSString *const ATEngagementInteractionsAppBuildNumberKey = @"ATEngagementInteractionsAppBuildNumberKey";


@implementation ApptentiveEngagementManifest

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_targets = [[ApptentiveTargets alloc] initWithTargetsDictionary:@{}];
		_interactions = @{};

		_expiry = [NSDate distantPast];
	}

	return self;
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime {
	self = [self init];

	if (self) {
		_expiry = [NSDate dateWithTimeIntervalSinceNow:cacheLifetime];
		_JSONDictionary = JSONDictionary;

		// Targets
		NSDictionary *targetsDictionary = JSONDictionary[@"targets"];
		if ([targetsDictionary isKindOfClass:[NSDictionary class]]) {
			_targets = [[ApptentiveTargets alloc] initWithTargetsDictionary:targetsDictionary];
		}

		// Interactions
		NSArray *interactionsArray = JSONDictionary[@"interactions"];

		if ([interactionsArray isKindOfClass:[NSArray class]]) {
			NSMutableDictionary *interactions = [NSMutableDictionary dictionary];

			for (NSDictionary *interactionDictionary in interactionsArray) {
				ApptentiveInteraction *interactionObject = [ApptentiveInteraction interactionWithJSONDictionary:interactionDictionary];
				ApptentiveDictionarySetKeyValue(interactions, interactionObject.identifier, interactionObject);
			}

			_interactions = [NSDictionary dictionaryWithDictionary:interactions];
		}
	}

	return self;
}

- (instancetype)initWithCachePath:(NSString *)cachePath userDefaults:(NSUserDefaults *)userDefaults {
	// Don't try to migrate legacy engagement manifests here, rather just download a new one.
	// (it's complicated and error prone and hard to test and not really valuable).
	return [self init];
}

+ (void)deleteMigratedDataFromCachePath:(NSString *)cachePath {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsSDKVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsAppBuildNumberKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];

	NSError *error;
	NSString *targetsCachePath = [cachePath stringByAppendingPathComponent:@"cachedtargets.objects"];
	if (![[NSFileManager defaultManager] removeItemAtPath:targetsCachePath error:&error]) {
		ApptentiveLogWarning(ApptentiveLogTagConversation, @"Unable to remove migrated target data: %@", error);
	}

	NSString *cachedInteractionsPath = [cachePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
	if (![[NSFileManager defaultManager] removeItemAtPath:cachedInteractionsPath error:&error]) {
		ApptentiveLogWarning(ApptentiveLogTagConversation, @"Unable to remove migrated interactions data: %@", error);
	}
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_targets = [coder decodeObjectOfClass:[ApptentiveTargets class] forKey:TargetsKey];
		NSSet *allowedClasses = [NSSet setWithArray:@[[NSDictionary class], [ApptentiveInteraction class]]];
		_interactions = [coder decodeObjectOfClasses:allowedClasses forKey:InteractionsKey];
		_expiry = [coder decodeObjectOfClass:[NSDate class] forKey:ExpiryKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.targets forKey:TargetsKey];
	[coder encodeObject:self.interactions forKey:InteractionsKey];
	[coder encodeObject:self.expiry forKey:ExpiryKey];
}

@end

NS_ASSUME_NONNULL_END
