//
//  ATSurveyQuestionResponse.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/22/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyQuestionResponse.h"

#define kATSurveyQuestionResponseStorageVersion 1

@implementation ATSurveyQuestionResponse
@synthesize identifier, response;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"survey_question_response_version"];
		if (version == kATSurveyQuestionResponseStorageVersion) {
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.response = [coder decodeObjectForKey:@"response"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionResponseStorageVersion forKey:@"survey_question_response_version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeObject:self.response forKey:@"response"];
}

- (void)dealloc {
	[identifier release], identifier = nil;
	[response release], response = nil;
	[super dealloc];
}
@end
