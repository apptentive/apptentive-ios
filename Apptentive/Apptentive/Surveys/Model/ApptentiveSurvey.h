//
//  ApptentiveSurvey.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveSurveyQuestion;


@interface ApptentiveSurvey : NSObject

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *surveyDescription;
@property (readonly, nonatomic) BOOL showSuccessMessage;
@property (readonly, nonatomic) NSString *successMessage;
@property (readonly, nonatomic) NSTimeInterval viewPeriod;
@property (readonly, nonatomic) NSArray<ApptentiveSurveyQuestion *> *questions;
@property (readonly, nonatomic) NSString *submitText;
@property (readonly, nonatomic) NSString *requiredText;
@property (readonly, nonatomic) NSString *validationErrorText;

@end

NS_ASSUME_NONNULL_END
