//
//  ApptentiveEventPayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveEventPayload : ApptentivePayload

@property (readonly, nonatomic) NSString *label;
@property (strong, nullable, nonatomic) NSString *interactionIdentifier;
@property (strong, nullable, nonatomic) NSDictionary<NSString *, id> *userInfo;
@property (strong, nullable, nonatomic) NSDictionary<NSString *, id> *customData;
@property (strong, nullable, nonatomic) NSArray<NSDictionary *> *extendedData;

- (nullable instancetype)initWithLabel:(NSString *)label creationDate:(NSDate *)creationDate;

@end

NS_ASSUME_NONNULL_END
