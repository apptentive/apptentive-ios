//
//  ATSurvey.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATSurveyQuestion;

@interface ATSurvey : NSObject

- (instancetype)initWithJSON:(NSDictionary *)JSON identifier:(NSString *)identifier;

@property (readonly, nonatomic) NSString *identifier;
@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *surveyDescription;
@property (readonly, nonatomic) BOOL required;
@property (readonly, nonatomic) BOOL multipleResponses;
@property (readonly, nonatomic) BOOL showSuccessMessage;
@property (readonly, nonatomic) NSString *successMessage;
@property (readonly, nonatomic) NSTimeInterval viewPeriod;
@property (readonly, nonatomic) NSArray<ATSurveyQuestion *> *questions;

@end
