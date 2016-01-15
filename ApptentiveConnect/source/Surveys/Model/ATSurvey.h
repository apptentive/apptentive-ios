//
//  ATSurvey.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATSurveyQuestion.h"


@interface ATSurvey : NSObject <NSCoding>
@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *surveyDescription;
@property (readonly, nonatomic) NSArray *questions;
@property (assign, nonatomic, getter=responseIsRequired) BOOL responseRequired;
@property (assign, nonatomic) BOOL showSuccessMessage;
@property (copy, nonatomic) NSString *successMessage;

- (void)addQuestion:(ATSurveyQuestion *)question;

- (void)reset;

@end
