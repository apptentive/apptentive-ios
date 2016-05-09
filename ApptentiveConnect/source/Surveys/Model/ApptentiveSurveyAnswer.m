//
//  ApptentiveSurveyAnswer.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswer.h"


@implementation ApptentiveSurveyAnswer

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		_identifier = JSON[@"id"];
		_value = JSON[@"value"];
		_type = [JSON[@"type"] isEqualToString:@"other"] ? ApptentiveSurveyAnswerTypeOther : ApptentiveSurveyAnswerTypeChoice;
	}

	return self;
}

@end
