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


@interface ATSurveyQuestion : NSObject <NSCoding>
@property (assign, nonatomic) ATSurveyQuestionType type;
@property (copy, nonatomic) NSString *identifier;
@property (assign, nonatomic, getter=responseIsRequired) BOOL responseRequired;
@property (copy, nonatomic) NSString *questionText;
@property (copy, nonatomic) NSString *instructionsText;
@property (copy, nonatomic) NSString *value;
@property (readonly, nonatomic) NSMutableArray *answerChoices;
@property (copy, nonatomic) NSString *answerText;
// If this is a multiple choice or multiple select question:
@property (strong, nonatomic) NSMutableArray *selectedAnswerChoices;
@property (assign, nonatomic) NSUInteger minSelectionCount;
@property (assign, nonatomic) NSUInteger maxSelectionCount;
@property (assign, nonatomic) BOOL multiline;

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer;

- (void)addSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer;
- (void)removeSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer;
- (ATSurveyQuestionValidationErrorType)validateAnswer;

- (void)reset;
@end


@interface ATSurveyQuestionAnswer : NSObject <NSCoding>
@property (copy, nonatomic) NSString *identifier;
@property (copy, nonatomic) NSString *value;
@end
