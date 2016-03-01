//
//  ATSurveyQuestion.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyQuestion.h"
#import "ATSurveyAnswer.h"

@interface NSArray (Shuffle)

- (NSArray *)apptentive_shuffledCopy;

@end

@implementation ATSurveyQuestion

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		NSString *type = JSON[@"type"];

		if ([type isEqualToString:@"multiselect"]) {
			_type = ATSurveyQuestionTypeMultipleSelect;
		} else if ([type isEqualToString:@"multichoice"]) {
			_type = ATSurveyQuestionTypeSingleSelect;
		} else {
			_type = [JSON[@"multiline"] boolValue] ? ATSurveyQuestionTypeMultipleLine : ATSurveyQuestionTypeSingleLine;
		}

		_identifier = JSON[@"id"];
		_instructions = JSON[@"instructions"];
		_value = JSON[@"value"];
		_placeholder = JSON[@"placeholder"];
		_required = [JSON[@"required"] boolValue];

		if (_type == ATSurveyQuestionTypeMultipleSelect) {
			_maximumSelectedCount = [JSON[@"max_selections"] integerValue];
			_minimumSelectedCount = [JSON[@"min_selections"] integerValue];
		} else {
			_maximumSelectedCount = 1;
			_minimumSelectedCount = _required ? 1 : 0;
		}

		NSMutableArray *mutableAnswers = [NSMutableArray array];

		for (NSDictionary *answerJSON in JSON[@"answer_choices"]) {
			[mutableAnswers addObject:[[ATSurveyAnswer alloc] initWithJSON:answerJSON]];
		}

		if ([JSON[@"randomize"] boolValue]) {
			_answers = [mutableAnswers apptentive_shuffledCopy];
		} else {
			_answers = [mutableAnswers copy];
		}
	}

	return self;
}

@end

@implementation NSArray (Shuffle)

- (NSArray *)apptentive_shuffledCopy {
	NSMutableArray *shuffled = [self mutableCopy];

	for (NSInteger i = self.count; i > 1; i--) {
		[shuffled exchangeObjectAtIndex:i - 1 withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
	}

	return [NSArray arrayWithArray:shuffled];
}

@end
