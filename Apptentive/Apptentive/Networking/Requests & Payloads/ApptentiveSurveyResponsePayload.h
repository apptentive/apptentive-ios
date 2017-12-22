//
//  ApptentiveSurveyResponsePayload.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyResponsePayload : ApptentivePayload

@property (readonly, nonatomic) NSDictionary *answers;
@property (readonly, nonatomic) NSString *identifier;

- (nullable instancetype)initWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier creationDate:(NSDate *)creationDate;

@end

NS_ASSUME_NONNULL_END
