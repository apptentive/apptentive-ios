//
//  ApptentiveCount.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN


/**
 An `ApptentiveCount` records information about when and how often a code point
 or interaction has been engaged.
 */
@interface ApptentiveCount : ApptentiveState

/**
 The total number of times the code point or interaction has been engaged.
 */
@property (readonly, nonatomic) NSInteger totalCount;

/**
 The number of times the code point or interaction has been engaged since the
 version last changed.
 */
@property (readonly, nonatomic) NSInteger versionCount;

/**
 The number of times the code point or interaction has been engaged since the
 build last changed.
 */
@property (readonly, nonatomic) NSInteger buildCount;

/**
 The time at which the code point or version was last invoked.
 */
@property (readonly, nullable, strong, nonatomic) NSDate *lastInvoked;


/**
 Initializes an `ApptentiveCount` object with the specified values.

 @param totalCount The total number of times the code point or interaction
 has been engaged.
 @param versionCount The number of times the code point or interaction has been
 engaged since the
 version last changed.
 @param buildCount The number of times the code point or interaction has been
 engaged since the
 build last changed.
 @param date The time at which the code point or version was last invoked.
 @return The newly-initialized count object.
 */
- (instancetype)initWithTotalCount:(NSInteger)totalCount versionCount:(NSInteger)versionCount buildCount:(NSInteger)buildCount lastInvoked:(nullable NSDate *)date;

#pragma mark - Mutation

/**
 Resets the total, version and build counts, and clears the last invoked time.
 */
- (void)resetAll;

/**
 Resets the version count.
 */
- (void)resetVersion;

/**
 Resets the build count.
 */
- (void)resetBuild;

/**
 Increments the total, version and build counts, and sets the last invoked
 time to the current time.
 */
- (void)invoke;


/**
 Adds the values from `otherCount` to the current object.

 @param oldCount The older count object, presumably from a previous version.
 @param newCount The newer count object, which would have been invoked last.
 @return The sum of the two count objects.

 @discussion If either is nil, the other one is returned. If both are nil, nil is returned.
 */
+ (ApptentiveCount *)mergeOldCount:(nullable ApptentiveCount *)oldCount withNewCount:(nullable ApptentiveCount *)newCount;

@end

NS_ASSUME_NONNULL_END
