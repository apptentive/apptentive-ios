//
//  ATSurvey.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurvey.h"

@implementation ATSurvey
@synthesize active;
@synthesize identifier=identifier$;
@synthesize name=name$;
@synthesize surveyDescription=surveyDescription$;
@synthesize questions;

- (id)init {
	if ((self = [super init])) {
		questions = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[questions release], questions = nil;
	[identifier$ release], identifier$ = nil;
	[name$ release], name$ = nil;
	[surveyDescription$ release], surveyDescription$ = nil;
	[super dealloc];
}

- (void)addQuestion:(ATSurveyQuestion *)question {
	[questions addObject:question];
}
@end
