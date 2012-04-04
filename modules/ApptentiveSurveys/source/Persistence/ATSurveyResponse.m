//
//  ATSurveyResponse.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyResponse.h"
#import "ATWebClient+SurveyAdditions.h"

#define kATSurveyStorageVersion 1
#define kATSurveyQuestionResponseStorageVersion 1

@implementation ATSurveyResponse
@synthesize identifier;

- (id)init {
	if ((self = [super init])) {
		questionResponses = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        int version = [coder decodeIntForKey:@"survey_version"];
        if (version == kATSurveyStorageVersion) {
            self.identifier = [coder decodeObjectForKey:@"identifier"];
			NSArray *d = [coder decodeObjectForKey:@"question_responses"];
			if (d != nil) {
				questionResponses = [d mutableCopy];
			} else {
				questionResponses = [[NSMutableArray alloc] init];
			}
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
    [coder encodeInt:kATSurveyStorageVersion forKey:@"survey_version"];
    [coder encodeObject:self.identifier forKey:@"identifier"];
    [coder encodeObject:questionResponses forKey:@"question_responses"];
}

- (void)dealloc {
	[identifier release], identifier = nil;
	[questionResponses release], questionResponses = nil;
	[super dealloc];
}

- (void)addQuestionResponse:(ATSurveyQuestionResponse *)response {
	[questionResponses addObject:response];
}

- (NSDictionary *)apiDictionary {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[super apiDictionary]];
	
	if (self.identifier) {
		[d setObject:self.identifier forKey:@"record[survey][id]"];
	}
	
	NSUInteger i = 0;
	for (ATSurveyQuestionResponse *response in questionResponses) {
		NSObject *responseObject = response.response;
		if (!responseObject) {
			responseObject = @"";
		}
		[d setObject:responseObject forKey:[NSString stringWithFormat:@"record[survey][responses][%@]", response.identifier]];
		i++;
	}
    return d;
}

- (ATAPIRequest *)requestForSendingRecord {
	return [[ATWebClient sharedClient] requestForPostingSurveyResponse:self];
}
@end


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
