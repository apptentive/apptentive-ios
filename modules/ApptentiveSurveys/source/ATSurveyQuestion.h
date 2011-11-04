//
//  ATSurveyQuestion.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	ATSurveyQuestionTypeSingeLine,
	ATSurveyQuestionTypeTextField,
	ATSurveyQuestionTypeMultipleChoice
} ATSurveyQuestionType;

@interface ATSurveyQuestion : NSObject {
@private
	ATSurveyQuestionType type;
}
@property (nonatomic, assign) ATSurveyQuestionType type;
@end
