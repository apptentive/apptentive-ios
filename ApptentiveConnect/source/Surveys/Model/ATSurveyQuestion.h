//
//  ATSurveyQuestion.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	ATSurveyQuestionTypeUnknown,
	ATSurveyQuestionTypeSingeLine,
	ATSurveyQuestionTypeMultipleChoice,
	ATSurveyQuestionTypeMultipleSelect,
} ATSurveyQuestionType;

typedef enum {
	ATSurveyQuestionValidationErrorNone,
	ATSurveyQuestionValidationErrorMissingRequiredAnswer,
	ATSurveyQuestionValidationErrorTooFewAnswers,
	ATSurveyQuestionValidationErrorTooManyAnswers,
} ATSurveyQuestionValidationErrorType;

@class ATSurveyQuestionAnswer;

@interface ATSurveyQuestion : NSObject {
@private
}
@property (nonatomic, assign) ATSurveyQuestionType type;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, getter=responseIsRequired) BOOL responseRequired;
@property (nonatomic, retain) NSString *questionText;
@property (nonatomic, retain) NSString *instructionsText;
@property (nonatomic, retain) NSString *value;
@property (nonatomic, readonly) NSMutableArray *answerChoices;
@property (nonatomic, retain) NSString *answerText;
// If this is a multiple choice or multiple select question:
@property (nonatomic, retain) NSMutableArray *selectedAnswerChoices;
@property (nonatomic, assign) NSUInteger minSelectionCount;
@property (nonatomic, assign) NSUInteger maxSelectionCount;

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer;

- (void)addSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer;
- (void)removeSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer;
- (ATSurveyQuestionValidationErrorType)validateAnswer;
@end

@interface ATSurveyQuestionAnswer : NSObject {
@private
}
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *value;
@end
