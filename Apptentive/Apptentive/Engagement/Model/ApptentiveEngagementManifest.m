//
//  ApptentiveEngagementManifest.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementManifest.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"

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
		_targets = @{};
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
			NSMutableDictionary *targets = [NSMutableDictionary dictionary];

			for (NSString *event in [targetsDictionary allKeys]) {
				NSArray *invocationsJSONArray = targetsDictionary[event];
				NSArray *invocationsArray = [ApptentiveInteractionInvocation invocationsWithJSONArray:invocationsJSONArray];
				ApptentiveDictionarySetKeyValue(targets, event, invocationsArray);
			}

			_targets = [NSDictionary dictionaryWithDictionary:targets];
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
	self = [super init];

	if (self) {
		_expiry = [userDefaults objectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];

		NSString *cachedTargetsPath = [cachePath stringByAppendingPathComponent:@"cachedtargets.objects"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:cachedTargetsPath]) {
			@try {
				_targets = [NSKeyedUnarchiver unarchiveObjectWithFile:cachedTargetsPath];
			} @catch (NSException *exception) {
				ApptentiveLogError(@"Unable to unarchive cached targets at path %@ (%@)", cachedTargetsPath, exception);
			}
		}

		NSString *cachedInteractionsPath = [cachePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:cachedInteractionsPath]) {
			@try {
				_interactions = [NSKeyedUnarchiver unarchiveObjectWithFile:cachedInteractionsPath];
			} @catch (NSException *exception) {
				ApptentiveLogError(@"Unable to unarchive cached interactions at path %@ (%@)", cachedInteractionsPath, exception);
			}
		}
	}

	return self;
}

+ (void)deleteMigratedDataFromCachePath:(NSString *)cachePath {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsSDKVersionKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementInteractionsAppBuildNumberKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATEngagementCachedInteractionsExpirationPreferenceKey];

	NSError *error;
	NSString *targetsCachePath = [cachePath stringByAppendingPathComponent:@"cachedtargets.objects"];
	if (![[NSFileManager defaultManager] removeItemAtPath:targetsCachePath error:&error]) {
		ApptentiveLogError(@"Unable to remove migrated target data: %@", error);
	}

	NSString *cachedInteractionsPath = [cachePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
	if (![[NSFileManager defaultManager] removeItemAtPath:cachedInteractionsPath error:&error]) {
		ApptentiveLogError(@"Unable to remove migrated interactions data: %@", error);
	}
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_targets = [coder decodeObjectOfClass:[NSDictionary class] forKey:TargetsKey];
		_interactions = [coder decodeObjectOfClass:[NSDictionary class] forKey:InteractionsKey];
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
