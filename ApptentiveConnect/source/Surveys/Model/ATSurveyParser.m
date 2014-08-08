//
//  ATSurveyParser.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyParser.h"
#import "ATJSONSerialization.h"
#import "ATSurveyQuestion.h"
#import "ATUtilities.h"

@interface ATSurveyParser ()
- (ATSurveyQuestionAnswer *)answerWithJSONDictionary:(NSDictionary *)jsonDictionary;
- (ATSurveyQuestion *)questionWithJSONDictionary:(NSDictionary *)jsonDictionary;
@end

@implementation ATSurveyParser

- (ATSurveyQuestionAnswer *)answerWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATSurveyQuestionAnswer *answer = [[ATSurveyQuestionAnswer alloc] init];
	BOOL failed = NO;
	
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"identifier", @"id", @"value", @"value", nil];
	
	for (NSString *key in keyMapping) {
		NSString *ivarName = [keyMapping objectForKey:key];
		NSObject *value = [jsonDictionary objectForKey:key];
		if (value && [value isKindOfClass:[NSString class]]) {
			[answer setValue:value forKey:ivarName];
		} else {
			failed = YES;
		}
	}
	
	if (failed) {
		[answer release], answer = nil;
	}
	return [answer autorelease];
}

- (ATSurveyQuestion *)questionWithJSONDictionary:(NSDictionary *)jsonDictionary {
	ATSurveyQuestion *question = [[ATSurveyQuestion alloc] init];
	BOOL failed = YES;
	
	NSDictionary *keyMapping = [NSDictionary dictionaryWithObjectsAndKeys:@"identifier", @"id", @"questionText", @"value", @"instructionsText", @"instructions", nil];
	
	for (NSString *key in keyMapping) {
		NSString *ivarName = [keyMapping objectForKey:key];
		NSObject *value = [jsonDictionary objectForKey:key];
		if (value && [value isKindOfClass:[NSString class]]) {
			[question setValue:value forKey:ivarName];
		}
	}
	
	do { // once
		NSObject *typeString = [jsonDictionary objectForKey:@"type"];
		if (typeString == nil || ![typeString isKindOfClass:[NSString class]]) {
			break;
		}
		
		if ([(NSString *)typeString isEqualToString:@"multichoice"]) {
			question.type = ATSurveyQuestionTypeMultipleChoice;
		} else if ([(NSString *)typeString isEqualToString:@"multiselect"]) {
			question.type = ATSurveyQuestionTypeMultipleSelect;
		} else if ([(NSString *)typeString isEqualToString:@"singleline"]) {
			question.type = ATSurveyQuestionTypeSingeLine;
			
			if ([jsonDictionary objectForKey:@"multiline"]) {
				question.multiline = [(NSNumber *)[jsonDictionary objectForKey:@"multiline"] boolValue];
			} else {
				question.multiline = YES;
			}
		} else {
			break;
		}
		
		if ([jsonDictionary objectForKey:@"required"] != nil) {
			question.responseRequired = [(NSNumber *)[jsonDictionary objectForKey:@"required"] boolValue];
		}
		
		NSUInteger answerChoicesCount = [(NSArray *)[jsonDictionary objectForKey:@"answer_choices"] count];
		
		if ([jsonDictionary objectForKey:@"max_selections"] != nil) {
			question.maxSelectionCount = [(NSNumber *)[jsonDictionary objectForKey:@"max_selections"] unsignedIntegerValue];
		} else {
			if (question.type == ATSurveyQuestionTypeMultipleChoice) {
				question.maxSelectionCount = 1;
			} else {
				question.maxSelectionCount = answerChoicesCount;
			}
		}
		
		if ([jsonDictionary objectForKey:@"min_selections"] != nil) {
			question.minSelectionCount = [(NSNumber *)[jsonDictionary objectForKey:@"min_selections"] unsignedIntegerValue];
		} else {
			// If question is required, at least one selection is required by defult.
			if (question.responseRequired && answerChoicesCount >= 1) {
				question.minSelectionCount = 1;
			} else {
				question.minSelectionCount = 0;
			}
		}
		
		if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			NSObject *answerChoices = [jsonDictionary objectForKey:@"answer_choices"];
			if (answerChoices == nil || ![answerChoices isKindOfClass:[NSArray class]]) {
				break;
			}
			
			for (NSObject *answerDict in (NSDictionary *)answerChoices) {
				if (![answerDict isKindOfClass:[NSDictionary class]]) {
					continue;
				}
				ATSurveyQuestionAnswer *answer = [self answerWithJSONDictionary:(NSDictionary *)answerDict];
				if (answer != nil) {
					[question addAnswerChoice:answer];
				}
			}
		}
		
		failed = NO;
	} while (NO);
	
	if (failed) {
		[question release], question = nil;
	}
	
	return [question autorelease];
}

- (ATSurvey *)surveyWithInteraction:(ATInteraction *)interaction {
	ATSurvey *survey = [[ATSurvey alloc] init];
	
	if (interaction.identifier) {
		survey.identifier = interaction.identifier;
	}
	
	if (interaction.configuration[@"name"]) {
		survey.name = interaction.configuration[@"name"];
	}
	
	if (interaction.configuration[@"description"]) {
		survey.surveyDescription = interaction.configuration[@"description"];
	}
	
	if (interaction.configuration[@"required"]) {
		survey.responseRequired = [interaction.configuration[@"required"] boolValue];
	}
	
	if (interaction.configuration[@"show_success_message"]) {
		survey.showSuccessMessage = [interaction.configuration[@"show_success_message"] boolValue];
	}
	
	if (interaction.configuration[@"success_message"]) {
		survey.successMessage = interaction.configuration[@"success_message"];
	}
	
	NSArray *questions = interaction.configuration[@"questions"];
	if ([questions isKindOfClass:[NSArray class]]) {
		for (NSObject *question in questions) {
			if ([question isKindOfClass:[NSDictionary class]]) {
				ATSurveyQuestion *result = [self questionWithJSONDictionary:(NSDictionary *)question];
				if (result) {
					[survey addQuestion:result];
				}
			}
		}
	}
	
	return [survey autorelease];
}

- (NSError *)parserError {
	return parserError;
}

- (void)dealloc {
	[parserError release], parserError = nil;
	[super dealloc];
}
@end
