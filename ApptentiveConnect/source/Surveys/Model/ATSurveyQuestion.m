//
//  ATSurveyQuestion.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyQuestion.h"

@implementation ATSurveyQuestion
@synthesize type;
@synthesize responseRequired;
@synthesize identifier;
@synthesize questionText;
@synthesize instructionsText;
@synthesize value;
@synthesize answerChoices;
@synthesize answerText;
@synthesize selectedAnswerChoices;
@synthesize minSelectionCount;
@synthesize maxSelectionCount;

- (id)init {
	if ((self = [super init])) {
		answerChoices = [[NSMutableArray alloc] init];
		selectedAnswerChoices = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[identifier release], identifier = nil;
	[questionText release], questionText = nil;
	[instructionsText release], instructionsText = nil;
	[value release], value = nil;
	[answerChoices release], answerChoices = nil;
	[answerText release], answerText = nil;
	[selectedAnswerChoices release], selectedAnswerChoices = nil;
	[super dealloc];
}

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	[self.answerChoices addObject:answer];
}

- (void)addSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	if (self.type == ATSurveyQuestionTypeMultipleChoice) {
		[self.selectedAnswerChoices removeAllObjects];
	}
	if (![self.selectedAnswerChoices containsObject:answer]) {
		[self.selectedAnswerChoices addObject:answer];
	}
}

- (void)removeSelectedAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	[self.selectedAnswerChoices removeObject:answer];
}

- (ATSurveyQuestionValidationErrorType)validateAnswer {
	ATSurveyQuestionValidationErrorType error = ATSurveyQuestionValidationErrorNone;
	
	if (self.type == ATSurveyQuestionTypeSingeLine) {
		if (self.responseIsRequired && (self.answerText == nil || [self.answerText length] == 0)) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleChoice) {
		if (self.responseIsRequired && [self.selectedAnswerChoices count] == 0) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleSelect) {
		if (self.responseIsRequired) {
			if (minSelectionCount != 0 && [self.selectedAnswerChoices count] < minSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooFewAnswers;
			} else if (maxSelectionCount != 0 && [self.selectedAnswerChoices count] > maxSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooManyAnswers;
			}
		}
	}
	return error;
}
@end

@implementation ATSurveyQuestionAnswer
@synthesize identifier;
@synthesize value;

- (void)dealloc {
	[identifier release], identifier = nil;
	[value release], value = nil;
	[super dealloc];
}
@end
