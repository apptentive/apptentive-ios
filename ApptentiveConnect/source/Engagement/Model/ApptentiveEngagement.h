//
//  ApptentiveEngagement.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentiveCount;

@interface ApptentiveEngagement : ApptentiveState

@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveCount *> *interactions;
@property (readonly, strong, nonatomic) NSDictionary<NSString *, ApptentiveCount *> *codePoints;

- (void)warmCodePoint:(NSString *)codePoint;
- (void)warmInteraction:(NSString *)interaction;

- (void)engageCodePoint:(NSString *)codePoint;
- (void)engageInteraction:(NSString *)interaction;

- (void)resetVersion;
- (void)resetBuild;

@end
