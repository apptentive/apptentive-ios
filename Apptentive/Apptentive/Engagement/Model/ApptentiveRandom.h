//
//  ApptentiveRandom.h
//  Apptentive
//
//  Created by Frank Schmitt on 6/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveRandom : ApptentiveState

@property (readonly, assign) double newRandomValue;

@end

NS_ASSUME_NONNULL_END
