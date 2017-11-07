//
//  ApptentiveSurveyQuestion.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/29/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyQuestion.h"
#import "ApptentiveSurveyAnswer.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSurveyQuestion

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		NSString *type = JSON[@"type"];

		if ([type isEqualToString:@"multiselect"]) {
			_type = ATSurveyQuestionTypeMultipleSelect;
		} else if ([type isEqualToString:@"multichoice"]) {
			_type = ATSurveyQuestionTypeSingleSelect;
		} else if ([type isEqualToString:@"range"]) {
			_type = ATSurveyQuestionTypeRange;
		} else if ([type isEqualToString:@"singleline"]) {
			_type = [JSON[@"multiline"] boolValue] ? ATSurveyQuestionTypeMultipleLine : ATSurveyQuestionTypeSingleLine;
		} else {
			return nil;
		}

		_identifier = JSON[@"id"];
		_instructions = JSON[@"instructions"];
		_value = JSON[@"value"];
		_placeholder = JSON[@"freeform_hint"];
		_required = [JSON[@"required"] boolValue];
		_errorMessage = JSON[@"error_message"];

		if (_type == ATSurveyQuestionTypeMultipleSelect) {
			_maximumSelectedCount = [JSON[@"max_selections"] integerValue];
			_minimumSelectedCount = [JSON[@"min_selections"] integerValue];
		} else {
			_maximumSelectedCount = 1;
			_minimumSelectedCount = _required ? 1 : 0;
		}

		NSMutableArray *mutableAnswers = [NSMutableArray array];

		if (_type == ATSurveyQuestionTypeRange) {
			NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];

			_minimumValue = [(JSON[@"min"] ?: @0)integerValue];
			_maximumValue = [(JSON[@"max"] ?: @10)integerValue];

			_minimumLabel = JSON[@"min_label"];
			_maximumLabel = JSON[@"max_label"];

			for (NSInteger i = _minimumValue; i <= _maximumValue; i++) {
				ApptentiveArrayAddObject(mutableAnswers, [[ApptentiveSurveyAnswer alloc] initWithValue:[numberFormatter stringFromNumber:@(i)]]);
			}
		} else {
			for (NSDictionary *answerJSON in JSON[@"answer_choices"]) {
				ApptentiveArrayAddObject(mutableAnswers, [[ApptentiveSurveyAnswer alloc] initWithJSON:answerJSON]);
			}
		}

		_answers = [mutableAnswers copy];
	}

	return self;
}

@end

NS_ASSUME_NONNULL_END
