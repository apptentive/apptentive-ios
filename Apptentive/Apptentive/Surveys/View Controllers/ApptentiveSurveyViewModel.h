//
//  ApptentiveSurveyViewModel.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswer.h"
#import "ApptentiveSurveyQuestion.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveSurvey, ApptentiveInteraction;

@protocol ATSurveyViewModelDelegate
, ApptentiveStyle;


@interface ApptentiveSurveyViewModel : NSObject

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Consider making this private
@property (readonly, nonatomic) ApptentiveInteraction *interaction;
@property (readonly, nonatomic) ApptentiveSurvey *survey;
@property (readonly, nonatomic) id<ApptentiveStyle> styleSheet;
@property (weak, nonatomic) id<ATSurveyViewModelDelegate> delegate;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *greeting;
@property (readonly, nonatomic) NSString *submitButtonText;

@property (readonly, nonatomic) BOOL showThankYou;
@property (readonly, nonatomic) NSString *thankYouText;
@property (readonly, nonatomic) NSString *missingRequiredItemText;

@property (readonly, nonatomic) NSIndexPath *firstInvalidAnswerIndexPath;

- (NSInteger)numberOfQuestionsInSurvey;
- (NSInteger)numberOfAnswersForQuestionAtIndex:(NSInteger)index;

- (NSString *)textOfQuestionAtIndex:(NSInteger)index;
- (nullable NSAttributedString *)instructionTextOfQuestionAtIndex:(NSInteger)index;
- (NSAttributedString *)placeholderTextOfAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (nullable NSString *)accessibilityHintForQuestionAtIndexPath:(NSIndexPath *)indexPath;
- (ATSurveyQuestionType)typeOfQuestionAtIndex:(NSInteger)index;
- (ApptentiveSurveyAnswerType)typeOfAnswerAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)textOfAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textOfChoiceAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)minimumLabelForQuestionAtIndex:(NSInteger)index;
- (NSString *)maximumLabelForQuestionAtIndex:(NSInteger)index;

- (nullable NSString *)errorMessageAtIndex:(NSInteger)index;

- (BOOL)answerIsSelectedAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)answerIsValidAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)answerIsValidForQuestionAtIndex:(NSInteger)index;

- (NSIndexPath *)indexPathForTextFieldTag:(NSInteger)tag;
- (NSInteger)textFieldTagForIndexPath:(NSIndexPath *)indexPath;

- (void)setText:(NSString *)text forAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)validate:(BOOL)isSubmit;
- (void)submit;

- (void)didCancel:(UIViewController *)presentingViewController;
- (void)didSubmit:(UIViewController *)presentingViewController;
- (void)commitChangeAtIndexPath:(NSIndexPath *)indexPath;

@property (readonly, nonatomic) NSDictionary *answers;

@end

@protocol ATSurveyViewModelDelegate <NSObject>

- (void)viewModel:(ApptentiveSurveyViewModel *)viewModel didDeselectAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)viewModelValidationChanged:(ApptentiveSurveyViewModel *)viewModel isValid:(BOOL)valid;

@end

NS_ASSUME_NONNULL_END
