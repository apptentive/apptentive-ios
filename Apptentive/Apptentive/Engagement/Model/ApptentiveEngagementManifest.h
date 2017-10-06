//
//  ApptentiveEngagementManifest.h
//  Apptentive
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveInteraction;


/**
 An `AppteniveEngagementManfiest` object describes the list of targets and
 interactions downloaded from the `/interactions` endpoint of the Apptentive
 server API.
 */
@interface ApptentiveEngagementManifest : NSObject <NSSecureCoding>

/**
 A dictionary whose keys are event code points, and whose values are arrays
 of interaction invocations (a combination of an interaction identfier and
 criteria that must be met for the interaction to be engage).
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, NSArray *> *targets;

/**
 A dictionary whose keys are interaction identifiers, and whose values are
 dictionaries that specify the configuration of an interaction.
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveInteraction *> *interactions;

/**
 The date after which the manifest should be re-downloaded.
 */
@property (strong, nonatomic) NSDate *expiry;


/**
 Initializes an engagement manifest using legacy values from the interactions
 cache and `NSUserDefaults`.

 @param cachePath The path to the cached targets and interactions.
 @param userDefaults The `NSUserDefaults` object (used for testing).
 @return The newly-migrated engagement manifest.
 */
- (instancetype)initWithCachePath:(NSString *)cachePath userDefaults:(NSUserDefaults *)userDefaults;

/**
 Initializes an engagement manifest with JSON downloaded from the Apptentive
 server API's `/interactions` endpoint.

 @param JSONDictionary A dictionary corresponding to the downloaded JSON data.
 @param cacheLifetime The number of seconds for which the engagement manifest
 should be considered up-to-date.
 @return The newly-created engagement manifest.
 */
- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime;


/**
 Deletes the migrated data from `NSUserDefaults` and the legacy on-disk cache.

 @param cachePath The path in which the legacy cache files are stored.
 */
+ (void)deleteMigratedDataFromCachePath:(NSString *)cachePath;

/**
 A dictionary representing the downloaded JSON. Used for debugging purposes
 only.
 */
@property (readonly, nonatomic) NSDictionary *JSONDictionary;

@end

NS_ASSUME_NONNULL_END
