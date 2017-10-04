//
//  ApptentiveEngagement.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveCount;


/**
 An `ApptentiveEngagement` object records the times and number of times that
 various code points and interactions have been invoked.
 */
@interface ApptentiveEngagement : ApptentiveState

/**
 The interactions for which the invocations are being recorded.
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveCount *> *interactions;

/**
 The code points for which the invocations are being added
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveCount *> *codePoints;

#pragma mark - Mutation

/**
 Initializes an empty `ApptentiveCount` object for the specified code point.

 @param codePoint The name of the code point whose count should be initialized.
 */
- (void)warmCodePoint:(NSString *)codePoint;

/**
 Initializes an empty `ApptentiveCount` object for the specified interaction.

 @param interaction The identifier of the interaction whose count should be
 initialized.
 */
- (void)warmInteraction:(NSString *)interaction;

/**
 Increments the count and sets the time for the specified code point.

 @param codePoint The name of the code point whose count should be incremented.
 */
- (void)engageCodePoint:(NSString *)codePoint;


/**
 Increments the count and sets the time for the specified interaction.

 @param interaction The identifier of the interaction whose count should be
 incremented.
 */
- (void)engageInteraction:(NSString *)interaction;

/**
 Resets the version count for every code point and interaction.
 */
- (void)resetVersion;

/**
 Resets the build count for every code point and interaction.
 */
- (void)resetBuild;

@end

NS_ASSUME_NONNULL_END
