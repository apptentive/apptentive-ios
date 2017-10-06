//
//  ApptentiveMessagePayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveMessage;


@interface ApptentiveMessagePayload : ApptentivePayload

@property (readonly, nonatomic) ApptentiveMessage *message;
@property (readonly, nonatomic) NSString *boundary;

- (nullable instancetype)initWithMessage:(ApptentiveMessage *)message;

@end

NS_ASSUME_NONNULL_END
