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
@synthesize identifier=identifier$;
@synthesize questionText=questionText$;
@synthesize value=value$;
@synthesize answerChoices=answerChoices$;
@synthesize answerText=answerText$;
@synthesize selectedAnswerChoices=selectedAnswerChoices$;
@synthesize maxSelectionCount;

- (id)init {
	if ((self = [super init])) {
		answerChoices$ = [[NSMutableArray alloc] init];
		selectedAnswerChoices$ = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[identifier$ release], identifier$ = nil;
	[questionText$ release], questionText$ = nil;
	[value$ release], value$ = nil;
	[answerChoices$ release], answerChoices$ = nil;
	[answerText$ release], answerText$ = nil;
	[selectedAnswerChoices$ release], selectedAnswerChoices$ = nil;
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
@end

@implementation ATSurveyQuestionAnswer
@synthesize identifier=identifier$;
@synthesize value=value$;

- (void)dealloc {
	[identifier$ release], identifier$ = nil;
	[value$ release], value$ = nil;
	[super dealloc];
}
@end
