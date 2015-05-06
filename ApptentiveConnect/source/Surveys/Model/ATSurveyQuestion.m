//
//  ATSurveyQuestion.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyQuestion.h"

#define kATSurveyQuestionStorageVersion 1
#define kATSurveyQuestionAnswerStorageVersion 1

@implementation ATSurveyQuestion 

- (id)init {
	if ((self = [super init])) {
		_answerChoices = [[NSMutableArray alloc] init];
		_selectedAnswerChoices = [[NSMutableArray alloc] init];
		self.multiline = YES;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		_answerChoices = [[NSMutableArray alloc] init];
		_selectedAnswerChoices = [[NSMutableArray alloc] init];
		if (version == kATSurveyQuestionStorageVersion) {
			self.type = [coder decodeIntForKey:@"type"];
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.responseRequired = [coder decodeBoolForKey:@"responseRequired"];
			self.questionText = [coder decodeObjectForKey:@"questionText"];
			self.instructionsText = [coder decodeObjectForKey:@"instructionsText"];
			self.value = [coder decodeObjectForKey:@"value"];
			
			NSArray *decodedAnswerChoices = [coder decodeObjectForKey:@"answerChoices"];
			if (decodedAnswerChoices) {
				[_answerChoices addObjectsFromArray:decodedAnswerChoices];
			}
			
			self.answerText = [coder decodeObjectForKey:@"answerText"];
			self.minSelectionCount = [(NSNumber *)[coder decodeObjectForKey:@"minSelectionCount"] unsignedIntegerValue];
			self.maxSelectionCount = [(NSNumber *)[coder decodeObjectForKey:@"maxSelectionCount"] unsignedIntegerValue];
			if ([coder decodeObjectForKey:@"multiline"]) {
				self.multiline = [(NSNumber *)[coder decodeObjectForKey:@"multiline"] boolValue];
			} else {
				self.multiline = YES;
			}
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionStorageVersion forKey:@"version"];
	[coder encodeInt:self.type forKey:@"type"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeBool:self.responseRequired forKey:@"responseRequired"];
	[coder encodeObject:self.questionText forKey:@"questionText"];
	[coder encodeObject:self.instructionsText forKey:@"instructionsText"];
	[coder encodeObject:self.value forKey:@"value"];
	[coder encodeObject:self.answerChoices forKey:@"answerChoices"];
	[coder encodeObject:self.answerText forKey:@"answerText"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:self.minSelectionCount] forKey:@"minSelectionCount"];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:self.maxSelectionCount] forKey:@"maxSelectionCount"];
	[coder encodeObject:[NSNumber numberWithBool:self.multiline] forKey:@"multiline"];
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
		NSString *trimmedText = self.answerText;
		if (trimmedText) {
			trimmedText = [trimmedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
		if (self.responseIsRequired && (trimmedText == nil || [trimmedText length] == 0)) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleChoice) {
		if (self.responseIsRequired && [self.selectedAnswerChoices count] == 0) {
			error = ATSurveyQuestionValidationErrorMissingRequiredAnswer;
		}
	} else if (self.type == ATSurveyQuestionTypeMultipleSelect) {
		NSUInteger answerCount = [self.selectedAnswerChoices count];
		
		if (self.responseIsRequired || answerCount > 0) {
			if (self.minSelectionCount != 0 && answerCount < self.minSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooFewAnswers;
			} else if (self.maxSelectionCount != 0 && answerCount > self.maxSelectionCount) {
				error = ATSurveyQuestionValidationErrorTooManyAnswers;
			}
		}
	}
	return error;
}

- (void)reset {
	[self.selectedAnswerChoices removeAllObjects];
	self.answerText = nil;
}
@end

@implementation ATSurveyQuestionAnswer

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATSurveyQuestionAnswerStorageVersion) {
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.value = [coder decodeObjectForKey:@"value"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyQuestionAnswerStorageVersion forKey:@"version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeObject:self.value forKey:@"value"];
}

@end
