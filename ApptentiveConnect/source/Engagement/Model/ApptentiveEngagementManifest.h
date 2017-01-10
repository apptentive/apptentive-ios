//
//  ApptentiveEngagementManifest.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveInteraction;

@interface ApptentiveEngagementManifest : NSObject <NSSecureCoding>

@property (readonly, strong, nonatomic) NSDictionary<NSString *, NSArray *> *targets;
@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveInteraction *> *interactions;

@property (strong, nonatomic) NSDate *expiry;

- (instancetype)initWithCachePath:(NSString *)cachePath userDefaults:(NSUserDefaults *)userDefaults;
- (instancetype)initWithJSONDictionary:(NSDictionary *)JSONDictionary cacheLifetime:(NSTimeInterval)cacheLifetime;

+ (void)deleteMigratedDataFromCachePath:(NSString *)cachePath;

@property (readonly, nonatomic) NSDictionary *JSONDictionary;

@end
