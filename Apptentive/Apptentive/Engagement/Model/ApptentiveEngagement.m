//
//  ApptentiveEngagement.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEngagement.h"
#import "ApptentiveCount.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const InteractionsKey = @"interactions";
static NSString *const CodePointsKey = @"codePoints";

// Legacy keys
static NSString *const ATEngagementCodePointsInvokesTotalKey = @"ATEngagementCodePointsInvokesTotalKey";
static NSString *const ATEngagementCodePointsInvokesVersionKey = @"ATEngagementCodePointsInvokesVersionKey";
static NSString *const ATEngagementCodePointsInvokesBuildKey = @"ATEngagementCodePointsInvokesBuildKey";
static NSString *const ATEngagementCodePointsInvokesLastDateKey = @"ATEngagementCodePointsInvokesLastDateKey";
static NSString *const ATEngagementInteractionsInvokesTotalKey = @"ATEngagementInteractionsInvokesTotalKey";
static NSString *const ATEngagementInteractionsInvokesVersionKey = @"ATEngagementInteractionsInvokesVersionKey";
static NSString *const ATEngagementInteractionsInvokesBuildKey = @"ATEngagementInteractionsInvokesBuildKey";
static NSString *const ATEngagementInteractionsInvokesLastDateKey = @"ATEngagementInteractionsInvokesLastDateKey";


@interface ApptentiveEngagement ()

@property (strong, nonatomic) NSMutableDictionary<NSString *, ApptentiveCount *> *mutableInteractions;
@property (strong, nonatomic) NSMutableDictionary<NSString *, ApptentiveCount *> *mutableCodePoints;

@end


@implementation ApptentiveEngagement

- (instancetype)init {
	self = [super init];
	if (self) {
		_mutableInteractions = [NSMutableDictionary dictionary];
		_mutableCodePoints = [NSMutableDictionary dictionary];
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		_mutableInteractions = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:InteractionsKey];
		_mutableCodePoints = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:CodePointsKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.mutableInteractions forKey:InteractionsKey];
	[coder encodeObject:self.mutableCodePoints forKey:CodePointsKey];
}

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

NS_ASSUME_NONNULL_END
