//
//  ATSurveyViewModel.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyViewModel.h"
#import "ATSurvey.h"
#import "ATSurveyQuestion.h"
#import "ATSurveyAnswer.h"

@interface ATSurveyViewModel ()

@property (strong, nonatomic) NSString *currentMultilineText;
@property (strong, nonatomic) NSMutableSet *selectedIndexPaths;
@property (strong, nonatomic) NSMutableDictionary *textAtIndexPath;
@property (strong, nonatomic) NSMutableIndexSet *invalidQuestionIndexes;

@end

@implementation ATSurveyViewModel

- (instancetype)initWithSurvey:(ATSurvey *)survey {
	self = [super init];
	if (self) {
		_survey = survey;

		self.selectedIndexPaths = [NSMutableSet set];
		self.textAtIndexPath = [NSMutableDictionary dictionary];
	}
	return self;
}

- (NSString *)title {
	return self.survey.title;
}

- (NSString *)greeting {
	return self.survey.surveyDescription;
}

- (NSString *)submitButtonText {
	// TODO: Localize me
	return @"Submit";
}

- (NSInteger)numberOfQuestionsInSurvey {
	return self.survey.questions.count;
}

- (NSInteger)numberOfAnswersForQuestionAtIndex:(NSInteger)index {
	if ([self typeOfQuestionAtIndex:index] == ATSurveyQuestionTypeSingleLine || [self typeOfQuestionAtIndex:index] == ATSurveyQuestionTypeMultipleLine) {
		return 1;
	} else {
		return [self questionAtIndex:index].answers.count;
	}
}

- (NSString *)textOfQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].value;
}

- (NSString *)instructionTextOfQuestionAtIndex:(NSInteger)index {
	NSMutableArray *parts = [NSMutableArray array];

	if ([self questionAtIndex:index].required) {
		// TODO: localize me
		[parts addObject:@"Required"];
	}

	if ([self questionAtIndex:index].instructions) {
		[parts addObject:[self questionAtIndex:index].instructions];
	}

	return [parts componentsJoinedByString:@" — "];
}

- (NSString *)placeholderTextOfQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].placeholder;
}

- (NSString *)textOfAnswerAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestion *question = [self questionAtIndex:indexPath.section];

	if (question.type == ATSurveyQuestionTypeSingleLine || question.type == ATSurveyQuestionTypeMultipleLine) {
		return self.textAtIndexPath[indexPath];
	} else {
		return [self answerAtIndexPath:indexPath].value;
	}
}

- (BOOL)answerAtIndexPathIsSelected:(NSIndexPath *)indexPath {
	return [self.selectedIndexPaths containsObject:indexPath];
}

- (ATSurveyQuestionType)typeOfQuestionAtIndex:(NSInteger)index {
	return [self questionAtIndex:index].type;
}

- (BOOL)answerIsValidForQuestionAtIndex:(NSInteger)index {
	return ![self.invalidQuestionIndexes containsIndex:index];
}

#pragma mark - Mutation

- (void)setText:(NSString *)text forAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.textAtIndexPath setObject:text forKey:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate];
	}
}

- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.selectedIndexPaths addObject:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate];
	}
}

- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.selectedIndexPaths removeObject:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate];
	}
}

- (BOOL)submit {
	[self validate];

	return self.invalidQuestionIndexes.count == 0;
}

#pragma mark - Validation & Output

- (void)validate {
	NSIndexSet *previousInvalidQuestionIndexes = self.invalidQuestionIndexes;

	self.invalidQuestionIndexes = [NSMutableIndexSet indexSet];

	[self.survey.questions enumerateObjectsUsingBlock:^(ATSurveyQuestion * _Nonnull question, NSUInteger index, BOOL * _Nonnull stop) {
		switch (question.type) {
			case ATSurveyQuestionTypeSingleLine:
			case ATSurveyQuestionTypeMultipleLine: {
				BOOL answerIsEmpty = [self.textAtIndexPath[[NSIndexPath indexPathForItem:0 inSection:index]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
				if (question.required && answerIsEmpty) {
					[self.invalidQuestionIndexes addIndex:index];
				}
				break;
			}
			case ATSurveyQuestionTypeSingleSelect:
			case ATSurveyQuestionTypeMultipleSelect: {
				NSInteger numberOfSelections = [self selectionsForQuestionAtIndex:index].count;
				BOOL numberOfSelectionsOutOfRange = numberOfSelections	> question.maximumSelectedCount || numberOfSelections < question.minimumSelectedCount;

				if ((question.required || numberOfSelections != 0) && numberOfSelectionsOutOfRange) {
						[self.invalidQuestionIndexes addIndex:index];
				}
				break;
			}
		}
	}];

	if (![self.invalidQuestionIndexes isEqualToIndexSet:previousInvalidQuestionIndexes]) {
		[self.delegate viewModelValidationChanged:self];
	}
}

- (NSDictionary *)answers {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	[self.survey.questions enumerateObjectsUsingBlock:^(ATSurveyQuestion * _Nonnull question, NSUInteger index, BOOL * _Nonnull stop) {
		switch (question.type) {
			case ATSurveyQuestionTypeSingleLine:
			case ATSurveyQuestionTypeMultipleLine: {
				NSString *text = [self.textAtIndexPath[[NSIndexPath indexPathForItem:0 inSection:index]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

				if (text.length > 0) {
					result[question.identifier] = text;
				}
				break;
			}
			case ATSurveyQuestionTypeSingleSelect: {
				NSArray *selections = [self selectionsForQuestionAtIndex:index];

				if (selections.count == 1) {
					result[question.identifier] = selections.firstObject;
				}

				break;
			}
			case ATSurveyQuestionTypeMultipleSelect: {
				NSArray *selections = [self selectionsForQuestionAtIndex:index];

				if (selections.count > 0) {
					result[question.identifier] = selections;
				}
				break;
			}
		}
	}];

	return result;
}

#pragma mark - Private

- (ATSurveyQuestion *)questionAtIndex:(NSInteger)index {
	return [self.survey.questions objectAtIndex:index];
}

- (ATSurveyAnswer *)answerAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *answers = [self questionAtIndex:indexPath.section].answers;

	return answers.count > indexPath.row ? answers[indexPath.row] : nil;
}

- (NSArray *)selectionsForQuestionAtIndex:(NSInteger)index {
	NSMutableArray *result = [NSMutableArray array];

	for (NSIndexPath *indexPath in self.selectedIndexPaths) {
		if (indexPath.section != index) {
			continue;
		} else {
			[result addObject:[self answerAtIndexPath:indexPath].identifier];
		}
	}

	return result;
}

@end
