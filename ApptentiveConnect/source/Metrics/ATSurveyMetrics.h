//
//  ATSurveyMetrics.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ATSurveyDidHideWindowNotification; // survey.cancel or survey.submit
extern NSString *const ATSurveyDidAnswerQuestionNotification; // survey.question_response

extern NSString *const ATSurveyWindowTypeKey;
extern NSString *const ATSurveyMetricsEventKey;
extern NSString *const ATSurveyMetricsSurveyIDKey;
extern NSString *const ATSurveyMetricsSurveyQuestionIDKey;

typedef enum {
	ATSurveyWindowTypeSurvey,
} ATSurveyWindowType;

typedef enum {
	ATSurveyEventUnknown,
	ATSurveyEventTappedCancel,
	ATSurveyEventTappedSend,
	ATSurveyEventAnsweredQuestion,
} ATSurveyEvent;
