//
//  ATSurvey.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurvey.h"

#define kATSurveyStorageVersion 1

@implementation ATSurvey
@synthesize responseRequired;
@synthesize multipleResponsesAllowed;
@synthesize active;
@synthesize identifier;
@synthesize name;
@synthesize surveyDescription;
@synthesize questions;
@synthesize successMessage;

- (id)init {
	if ((self = [super init])) {
		questions = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		questions = [[NSMutableArray alloc] init];
		if (version == kATSurveyStorageVersion) {
			self.active = [coder decodeBoolForKey:@"active"];
			self.responseRequired = [coder decodeBoolForKey:@"responseRequired"];
			self.multipleResponsesAllowed = [coder decodeBoolForKey:@"multipleResponsesAllowed"];
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.surveyDescription = [coder decodeObjectForKey:@"surveyDescription"];
			NSArray *decodedQuestions = [coder decodeObjectForKey:@"questions"];
			if (decodedQuestions) {
				[questions addObjectsFromArray:decodedQuestions];
			}
			self.successMessage = [coder decodeObjectForKey:@"successMessage"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyStorageVersion forKey:@"version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeBool:self.isActive forKey:@"active"];
	[coder encodeBool:self.responseIsRequired forKey:@"responseRequired"];
	[coder encodeBool:self.multipleResponsesAllowed forKey:@"multipleResponsesAllowed"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.surveyDescription forKey:@"surveyDescription"];
	[coder encodeObject:self.questions forKey:@"questions"];
	[coder encodeObject:self.successMessage forKey:@"successMessage"];
}

- (void)dealloc {
	[questions release], questions = nil;
	[identifier release], identifier = nil;
	[name release], name = nil;
	[surveyDescription release], surveyDescription = nil;
	[successMessage release], successMessage = nil;
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<ATSurvey: %p {name:%@, identifier:%@}>", self, self.name, self.identifier];
}

- (void)addQuestion:(ATSurveyQuestion *)question {
	[questions addObject:question];
}

- (BOOL)isEligibleToBeShown {
	BOOL eligible = NO;
	NSString *reasonForNotShowingSurvey = nil;
	
	do { // once
		if (![self isActive]) {
			reasonForNotShowingSurvey = @"survey is not active.";
			break;
		}
		
		eligible = YES;
	} while (NO);
	
	if (reasonForNotShowingSurvey) {
		ATLogInfo(@"Did not show Apptentive survey %@ because %@", self.identifier, reasonForNotShowingSurvey);
	}
	
	return eligible;
}

- (void)reset {
	for (ATSurveyQuestion *question in questions) {
		[question reset];
	}
}

@end
