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

#import "Apptentive_Private.h"
#import "ATInteraction.h"
#import "ATSurveyResponse.h"
#import "ATSurveyResponseTask.h"
#import "ATSurveyMetrics.h"
#import "ATTaskQueue.h"
#import "ATData.h"


@interface ATSurveyViewModel ()

@property (strong, nonatomic) NSString *currentMultilineText;
@property (strong, nonatomic) NSMutableSet *selectedIndexPaths;
@property (strong, nonatomic) NSMutableDictionary *textAtIndexPath;
@property (strong, nonatomic) NSMutableIndexSet *invalidQuestionIndexes;

@end


@implementation ATSurveyViewModel

- (instancetype)initWithInteraction:(ATInteraction *)interaction {
	self = [super init];
	if (self) {
		_interaction = interaction;
		_survey = [[ATSurvey alloc] initWithJSON:interaction.configuration];

		self.selectedIndexPaths = [NSMutableSet set];
		self.textAtIndexPath = [NSMutableDictionary dictionary];
	}
	return self;
}

- (ApptentiveStyleSheet *)styleSheet {
	return [Apptentive sharedConnection].styleSheet;
}

- (NSString *)title {
	return self.survey.title;
}

- (NSString *)greeting {
	return self.survey.surveyDescription;
}

- (NSString *)submitButtonText {
	return ATLocalizedString(@"Submit", @"Survey submit button text");
}

- (BOOL)showThankYou {
	return self.survey.showSuccessMessage;
}

- (NSString *)thankYouText {
	return self.survey.successMessage;
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
		[parts addObject:ATLocalizedString(@"required", @"Survey answer requires response")];
	}

	if ([self questionAtIndex:index].instructions) {
		[parts addObject:[self questionAtIndex:index].instructions];
	}

	return parts.count > 0 ? [parts componentsJoinedByString:@"—"] : nil;
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
		[self validate:NO];
	}
}

- (void)commitChangeAtIndexPath:(NSIndexPath *)indexPath {
	[self answerChangedAtIndexPath:indexPath];
}

- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.selectedIndexPaths containsObject:indexPath])
		return;

	[self.selectedIndexPaths addObject:indexPath];

	if ([self typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeSingleSelect) {
		for (NSInteger answerIndex = 0; answerIndex < [self numberOfAnswersForQuestionAtIndex:indexPath.section]; answerIndex++) {
			if (answerIndex != indexPath.item) {
				NSIndexPath *deselectIndexPath = [NSIndexPath indexPathForItem:answerIndex inSection:indexPath.section];
				[self.delegate viewModel:self didDeselectAnswerAtIndexPath:deselectIndexPath];
				[self.selectedIndexPaths removeObject:deselectIndexPath];
			}
		}
	}

	[self answerChangedAtIndexPath:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate:NO];
	}
}

- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.selectedIndexPaths removeObject:indexPath];

	[self answerChangedAtIndexPath:indexPath];

	if (self.invalidQuestionIndexes) {
		[self validate:NO];
	}
}

- (void)submit {
	ATSurveyResponse *response = (ATSurveyResponse *)[ATData newEntityNamed:@"ATSurveyResponse"];

	[response setup];
	response.pendingState = [NSNumber numberWithInt:ATPendingSurveyResponseStateSending];
	response.surveyID = self.interaction.identifier;
	[response updateClientCreationTime];
	[response setAnswers:self.answers];
	[ATData save];

	NSString *pendingSurveyResponseID = [response pendingSurveyResponseID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		ATSurveyResponseTask *task = [[ATSurveyResponseTask alloc] init];
		task.pendingSurveyResponseID = pendingSurveyResponseID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
	});

	NSDictionary *notificationInfo = @{ATSurveyIDKey: (self.interaction.identifier ?: [NSNull null])};
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveySentNotification object:nil userInfo:notificationInfo];
}

#pragma mark - Validation & Output

- (BOOL)validate:(BOOL)isSubmit {
	NSIndexSet *previousInvalidQuestionIndexes = self.invalidQuestionIndexes;

	self.invalidQuestionIndexes = [NSMutableIndexSet indexSet];

	[self.survey.questions enumerateObjectsUsingBlock:^(ATSurveyQuestion *_Nonnull question, NSUInteger index, BOOL *_Nonnull stop) {
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

	// Unless the submit button was tapped, only allow answers to go from red to green
	if (!isSubmit) {
		NSMutableIndexSet *redToGreenQuestionIndexes = [self.invalidQuestionIndexes mutableCopy];
		[self.invalidQuestionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
			if (![previousInvalidQuestionIndexes containsIndex:idx]) {
				[redToGreenQuestionIndexes removeIndex:idx];
			}
		}];

		self.invalidQuestionIndexes = redToGreenQuestionIndexes;
	}

	if (![self.invalidQuestionIndexes isEqualToIndexSet:previousInvalidQuestionIndexes]) {
		[self.delegate viewModelValidationChanged:self];
	}

	return self.invalidQuestionIndexes.count == 0;
}

- (NSDictionary *)answers {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	[self.survey.questions enumerateObjectsUsingBlock:^(ATSurveyQuestion *_Nonnull question, NSUInteger index, BOOL *_Nonnull stop) {
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

#pragma mark - Metrics

- (void)answerChangedAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestion *question = [self questionAtIndex:indexPath.section];

	NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.interaction.identifier ?: [NSNull null],
		ATSurveyMetricsSurveyQuestionIDKey: question.identifier ?: [NSNull null],
		ATSurveyMetricsEventKey: @(ATSurveyEventAnsweredQuestion),
		@"interaction_id": self.interaction.identifier ?: [NSNull null],
	};

	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidAnswerQuestionNotification object:nil userInfo:metricsInfo];
}

- (void)didCancel {
	[self didCloseWindowWithEvent:ATSurveyEventTappedCancel];
}

- (void)didSubmit {
	[self didCloseWindowWithEvent:ATSurveyEventTappedSend];
}

- (void)didCloseWindowWithEvent:(ATSurveyEvent)event {
	NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.interaction.identifier ?: [NSNull null],
		ATSurveyWindowTypeKey: @(ATSurveyWindowTypeSurvey),
		ATSurveyMetricsEventKey: @(event),
		@"interaction_id": self.interaction.identifier ?: [NSNull null],
	};

	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidHideWindowNotification object:nil userInfo:metricsInfo];
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
		} else if ([self answerAtIndexPath:indexPath].identifier != nil) {
			[result addObject:[self answerAtIndexPath:indexPath].identifier];
		}
	}

	return result;
}

@end
