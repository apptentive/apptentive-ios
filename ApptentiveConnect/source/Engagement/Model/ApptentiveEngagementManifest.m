//
//  ApptentiveEngagementManifest.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagementManifest.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"

static NSString * const TargetsKey = @"targets";
static NSString * const InteractionsKey = @"interactions";
static NSString * const ExpiryKey = @"expiry";

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
	self = [super init];

	if (self) {
		_expiry = [NSDate dateWithTimeIntervalSinceNow:cacheLifetime];

		// Targets
		NSMutableDictionary *targets = [NSMutableDictionary dictionary];
		NSDictionary *targetsDictionary = JSONDictionary[@"targets"];
		for (NSString *event in [targetsDictionary allKeys]) {
			NSArray *invocationsJSONArray = targetsDictionary[event];
			NSArray *invocationsArray = [ApptentiveInteractionInvocation invocationsWithJSONArray:invocationsJSONArray];
			[targets setObject:invocationsArray forKey:event];
		}

		_targets = [NSDictionary dictionaryWithDictionary:targets];

		// Interactions
		NSMutableDictionary *interactions = [NSMutableDictionary dictionary];
		NSArray *interactionsArray = JSONDictionary[@"interactions"];
		for (NSDictionary *interactionDictionary in interactionsArray) {
			ApptentiveInteraction *interactionObject = [ApptentiveInteraction interactionWithJSONDictionary:interactionDictionary];
			[interactions setObject:interactionObject forKey:interactionObject.identifier];
		}

		_interactions = [NSDictionary dictionaryWithDictionary:interactions];
	}

	return self;
}

- (instancetype)initWithCachePath:(NSString *)cachePath userDefaults:(NSUserDefaults *)userDefaults {
	self = [super init];

	if (self) {
		_expiry = [userDefaults objectForKey:@"ATEngagementCachedInteractionsExpirationPreferenceKey"];

		NSString *targetsCachePath = [cachePath stringByAppendingPathComponent:@"cachedtargets.objects"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:targetsCachePath]) {
			_targets = [NSKeyedUnarchiver unarchiveObjectWithFile:targetsCachePath];
		}

		NSString *cachedInteractionsPath = [cachePath stringByAppendingPathComponent:@"cachedinteractionsV2.objects"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:cachedInteractionsPath]) {
			_interactions = [NSKeyedUnarchiver unarchiveObjectWithFile:cachedInteractionsPath];
		}
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
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
