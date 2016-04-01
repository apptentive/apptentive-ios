//
//  ATSurvey.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurvey.h"
#import "ApptentiveSurveyQuestion.h"


@implementation ApptentiveSurvey

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		_title = JSON[@"title"];
		_name = JSON[@"name"];
		_surveyDescription = JSON[@"description"];
		_showSuccessMessage = [JSON[@"show_success_message"] boolValue];
		_successMessage = JSON[@"success_message"];
		_viewPeriod = [JSON[@"view_period"] doubleValue];

		NSMutableArray *mutableQuestions = [NSMutableArray array];

		for (NSDictionary *questionJSON in JSON[@"questions"]) {
			[mutableQuestions addObject:[[ApptentiveSurveyQuestion alloc] initWithJSON:questionJSON]];
		}

		_questions = [mutableQuestions copy];
	}

	return self;
}

@end
