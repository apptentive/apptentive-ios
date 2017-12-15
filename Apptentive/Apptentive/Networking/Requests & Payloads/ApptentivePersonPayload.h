//
//  ApptentivePersonPayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentivePersonPayload : ApptentivePayload

@property (readonly, nonatomic) NSDictionary *personDiffs;

- (instancetype)initWithPersonDiffs:(NSDictionary *)personDiffs;

@end

NS_ASSUME_NONNULL_END
