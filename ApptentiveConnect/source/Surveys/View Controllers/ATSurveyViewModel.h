//
//  ATSurveyViewModel.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATSurveyQuestion.h"

@class ATSurvey;

@protocol  ATSurveyViewModelDelegate;

@interface ATSurveyViewModel : NSObject

- (instancetype)initWithSurvey:(ATSurvey *)survey NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

// Consider making this private
@property (readonly, nonatomic) ATSurvey *survey;
@property (weak, nonatomic) id<ATSurveyViewModelDelegate> delegate;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *greeting;
@property (readonly, nonatomic) NSString *submitButtonText;
@property (readonly, nonatomic) NSString *thankYouText;

- (NSInteger)numberOfQuestionsInSurvey;
- (NSInteger)numberOfAnswersForQuestionAtIndex:(NSInteger)index;

- (NSString *)textOfQuestionAtIndex:(NSInteger)index;
- (NSString *)instructionTextOfQuestionAtIndex:(NSInteger)index;
- (NSString *)placeholderTextOfQuestionAtIndex:(NSInteger)index;
- (ATSurveyQuestionType)typeOfQuestionAtIndex:(NSInteger)index;

- (NSString *)textOfAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)answerAtIndexPathIsSelected:(NSIndexPath *)indexPath;
- (BOOL)answerIsValidForQuestionAtIndex:(NSInteger)index;

- (void)setText:(NSString *)text forAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)selectAnswerAtIndexPath:(NSIndexPath *)indexPath;
- (void)deselectAnswerAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)submit;

@property (readonly, nonatomic) NSDictionary *answers;

@end

@protocol  ATSurveyViewModelDelegate <NSObject>

- (void)viewModelValidationChanged:(ATSurveyViewModel *)viewModel;

@end
