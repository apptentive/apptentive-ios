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
@synthesize identifier=identifier$;
@synthesize questionText=questionText$;
@synthesize value=value$;
@synthesize answerChoices=answerChoices$;

- (id)init {
	if ((self = [super init])) {
		answerChoices$ = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[identifier$ release], identifier$ = nil;
	[questionText$ release], questionText$ = nil;
	[value$ release], value$ = nil;
	[answerChoices$ release], answerChoices$ = nil;
	[super dealloc];
}

- (void)addAnswerChoice:(ATSurveyQuestionAnswer *)answer {
	[self.answerChoices addObject:answer];
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
