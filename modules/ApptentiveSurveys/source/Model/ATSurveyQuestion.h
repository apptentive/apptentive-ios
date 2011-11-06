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
	ATSurveyQuestionTypeMultipleChoice
} ATSurveyQuestionType;

@class ATSurveyQuestionAnswer;

@interface ATSurveyQuestion : NSObject {
@private
}
@property (nonatomic, assign) ATSurveyQuestionType type;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *questionText;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, readonly) NSMutableArray *answerChoices;
@property (nonatomic, retain) NSString *answerText;

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer;
@end

@interface ATSurveyQuestionAnswer : NSObject {
@private
}
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *value;
@end
