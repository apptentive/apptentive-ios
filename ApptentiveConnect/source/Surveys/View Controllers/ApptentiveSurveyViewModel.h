//
//  ApptentiveSurveyViewModel.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveSurveyQuestion.h"

@class ApptentiveSurvey, ApptentiveInteraction, ApptentiveStyleSheet;

@protocol ATSurveyViewModelDelegate;


@interface ApptentiveSurveyViewModel : NSObject

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Consider making this private
@property (readonly, nonatomic) ApptentiveInteraction *interaction;
@property (readonly, nonatomic) ApptentiveSurvey *survey;
@property (readonly, nonatomic) ApptentiveStyleSheet *styleSheet;
@property (weak, nonatomic) id<ATSurveyViewModelDelegate> delegate;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *greeting;
@property (readonly, nonatomic) NSString *submitButtonText;

@property (readonly, nonatomic) BOOL showThankYou;
@property (readonly, nonatomic) NSString *thankYouText;
@property (readonly, nonatomic) NSString *missingRequiredItemText;

- (NSInteger)numberOfQuestionsInSurvey;
- (NSInteger)numberOfAnswersForQuestionAtIndex:(NSInteger)index;

- (NSString *)textOfQuestionAtIndex:(NSInteger)index;
- (NSAttributedString *)instructionTextOfQuestionAtIndex:(NSInteger)index;
- (NSString *)placeholderTextOfQuestionAtIndex:(NSInteger)index;
- (ATSurveyQuestionType)typeOfQuestionAtIndex:(NSInteger)index;

- (NSString *)textOfAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)answerAtIndexPathIsSelected:(NSIndexPath *)indexPath;
- (BOOL)answerIsValidForQuestionAtIndex:(NSInteger)index;

- (void)setText:(NSString *)text forAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)validate:(BOOL)isSubmit;
- (void)submit;

- (void)didCancel;
- (void)didSubmit;
- (void)commitChangeAtIndexPath:(NSIndexPath *)indexPath;

@property (readonly, nonatomic) NSDictionary *answers;

@end

@protocol ATSurveyViewModelDelegate <NSObject>

- (void)viewModel:(ApptentiveSurveyViewModel *)viewModel didDeselectAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)viewModelValidationChanged:(ApptentiveSurveyViewModel *)viewModel isValid:(BOOL)valid;

@end
