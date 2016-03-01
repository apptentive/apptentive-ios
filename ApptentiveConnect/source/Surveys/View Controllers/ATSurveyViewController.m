//
//  ATSurveyViewController.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/22/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyViewController.h"
#import "ATSurveyViewModel.h"
#import "ATSurveyAnswerCell.h"
#import "ATSurveyChoiceCell.h"
#import "ATSurveySingleLineCell.h"
#import "ATSurveyMultilineCell.h"
#import "ATSurveyQuestionView.h"
#import "ATSurveyCollectionViewLayout.h"
#import "ATSurveyQuestionBackgroundView.h"
#import "ATSurveyOptionButton.h"
#import "ATSurveySubmitButton.h"
#import "ATSurveyGreetingView.h"

#import "ATBackend.h"

// These need to match the values from the storyboard
#define QUESTION_HORIZONTAL_MARGIN 38.0
#define QUESTION_VERTICAL_MARGIN 36.0
#define QUESTION_FONT [UIFont systemFontOfSize:17.0]
#define INSTRUCTIONS_FONT [UIFont systemFontOfSize:12.0]

#define CHOICE_HORIZONTAL_MARGIN 77.0
#define CHOICE_VERTICAL_MARGIN 23.5
#define CHOICE_FONT [UIFont systemFontOfSize:17.0]

#define MULTILINE_HORIZONTAL_MARGIN 44
#define MULTILINE_VERTICAL_MARGIN 14
#define MULTILINE_FONT [UIFont systemFontOfSize:14.0]

@interface ATSurveyViewController ()

@property (strong, nonatomic) IBOutlet ATSurveyGreetingView *headerView;
@property (strong, nonatomic) IBOutlet UIView *footerView;

@property (strong, nonatomic) IBOutlet ATSurveySubmitButton *submitButton;

@property (strong, nonatomic) NSIndexPath *editingIndexPath;

@end

@implementation ATSurveyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

	self.collectionView.allowsMultipleSelection = YES;
	[self.collectionViewLayout registerClass:[ATSurveyQuestionBackgroundView class]  forDecorationViewOfKind:@"QuestionBackground"];

	self.title = self.viewModel.title;

	self.headerView.greetingLabel.text = self.viewModel.greeting;
	[self.headerView.infoButton setImage:[ATBackend imageNamed:@"at_info"] forState:UIControlStateNormal];
	((ATCollectionView *)self.collectionView).collectionHeaderView = self.headerView;
	((ATCollectionView *)self.collectionView).collectionFooterView = self.footerView;

	// iOS 7 and 8 don't seem to adjust the contentInset for the keyboard
	if (![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillHideNotification object:nil];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[self.collectionViewLayout invalidateLayout];
}

- (void)viewWillLayoutSubviews {
	[self.collectionViewLayout invalidateLayout];
}

- (IBAction)submit:(id)sender {
	if ([self.viewModel submit]) {
		[self dismissViewControllerAnimated:YES completion:nil];

		// TODO: thank-you
		//debug
		NSLog(@"Answers are %@", self.viewModel.answers);
	}
}

- (IBAction)close:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setViewModel:(ATSurveyViewModel *)viewModel {
	_viewModel.delegate = nil;

	_viewModel = viewModel;

	viewModel.delegate = self;
}

#pragma mark Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.viewModel numberOfQuestionsInSurvey];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.viewModel numberOfAnswersForQuestionAtIndex:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:
(NSIndexPath *)indexPath {
	switch ([self.viewModel typeOfQuestionAtIndex:indexPath.section]) {
		case ATSurveyQuestionTypeMultipleLine: {
			ATSurveyMultilineCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultilineText" forIndexPath:indexPath];

			cell.textView.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			cell.placeholderLabel.text = [self.viewModel placeholderTextOfQuestionAtIndex:indexPath.section];
			cell.textView.delegate = self;
			cell.textView.tag = indexPath.section;
			cell.textView.accessibilityLabel = [self.viewModel placeholderTextOfQuestionAtIndex:indexPath.section];

			return cell;
		}
		case ATSurveyQuestionTypeSingleLine: {
			ATSurveySingleLineCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SingleLineText" forIndexPath:indexPath];

			cell.textField.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			cell.textField.placeholder = [self.viewModel placeholderTextOfQuestionAtIndex:indexPath.section];
			cell.textField.delegate = self;
			cell.textField.tag = indexPath.section;

			return cell;
		}
		case ATSurveyQuestionTypeSingleSelect:
		case ATSurveyQuestionTypeMultipleSelect: {
			NSString *reuseIdentifier = [self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeSingleSelect ? @"Radio" : @"Checkbox";
			UIImage *buttonImage = [ATBackend imageNamed:[self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeSingleSelect ? @"at_circle" : @"at_checkmark"];

			ATSurveyChoiceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

			cell.textLabel.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			cell.accessibilityLabel = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			[cell.button setImage:buttonImage  forState:UIControlStateNormal];

			return cell;
		}
	}

    return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if (kind == UICollectionElementKindSectionHeader) {
		ATSurveyQuestionView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Question" forIndexPath:indexPath];
		view.textLabel.text = [self.viewModel textOfQuestionAtIndex:indexPath.section];
		view.instructionsTextLabel.text = [self.viewModel instructionTextOfQuestionAtIndex:indexPath.section];

		return view;
	} else {
		return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
	}
}

- (BOOL)sectionAtIndexIsValid:(NSInteger)index {
	return [self.viewModel answerIsValidForQuestionAtIndex:index];
}

#pragma mark Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeSingleSelect) {
		for (NSInteger answerIndex = 0; answerIndex < [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section]; answerIndex++) {
			if (answerIndex != indexPath.item) {
				NSIndexPath *deselectIndexPath = [NSIndexPath indexPathForItem:answerIndex inSection:indexPath.section];
				[self.collectionView deselectItemAtIndexPath:deselectIndexPath animated:YES];
				[self.viewModel deselectAnswerAtIndexPath:deselectIndexPath];
			}
		}
	}

	[self.viewModel selectAnswerAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.viewModel deselectAnswerAtIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestionType questionType = [self.viewModel typeOfQuestionAtIndex:indexPath.section];

	return (questionType == ATSurveyQuestionTypeMultipleSelect || questionType == ATSurveyQuestionTypeSingleSelect);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestionType questionType = [self.viewModel typeOfQuestionAtIndex:indexPath.section];

	// Don't let them unselect the selected answer in a single select question
	if (questionType == ATSurveyQuestionTypeSingleSelect) {
		for (NSInteger answerIndex = 0; answerIndex < [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section]; answerIndex++) {
			if ([self.viewModel answerAtIndexPathIsSelected:[NSIndexPath indexPathForItem:answerIndex inSection:indexPath.section]]) {
				return NO;
			}
		}

		return YES;
	} else if (questionType == ATSurveyQuestionTypeMultipleSelect) {
		return YES;
	} else {
		return NO;
	}
}

#pragma mark Collection View Flow Layout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;

	CGSize itemSize = CGSizeMake(collectionView.bounds.size.width - sectionInset.left - sectionInset.right, 44.0);

	switch ([self.viewModel typeOfQuestionAtIndex:indexPath.section]) {
		case ATSurveyQuestionTypeSingleSelect:
		case ATSurveyQuestionTypeMultipleSelect: {
			CGFloat labelWidth = itemSize.width - CHOICE_HORIZONTAL_MARGIN;

			CGSize labelSize = CGRectIntegral([[self.viewModel textOfAnswerAtIndexPath:indexPath] boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : CHOICE_FONT } context:nil]).size;

			itemSize.height = labelSize.height + CHOICE_VERTICAL_MARGIN;
			break;
		}
		case ATSurveyQuestionTypeSingleLine:
			itemSize.height = 44.0;
			break;
		case ATSurveyQuestionTypeMultipleLine: {
			CGFloat textViewWidth = itemSize.width - MULTILINE_HORIZONTAL_MARGIN;

			NSString *text = [[self.viewModel textOfAnswerAtIndexPath:indexPath] ?: @" " stringByAppendingString:@"\n"];
			CGSize textSize = CGRectIntegral([text boundingRectWithSize:CGSizeMake(textViewWidth, MAXFLOAT)  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : MULTILINE_FONT } context:nil]).size;

			itemSize.height = fmax(textSize.height, 17.0) + MULTILINE_VERTICAL_MARGIN + 13;
			break;
		}
	}

	return itemSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;
	CGSize headerSize = CGSizeMake(collectionView.bounds.size.width - sectionInset.left - sectionInset.right, 44.0);
	CGFloat labelWidth = headerSize.width - QUESTION_HORIZONTAL_MARGIN;

	CGSize labelSize = CGRectIntegral([[self.viewModel textOfQuestionAtIndex:section] boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)  options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName : QUESTION_FONT } context:nil]).size;

	CGFloat instructionsHeight = [self.viewModel instructionTextOfQuestionAtIndex:section] ? 15 : 0;

	return CGSizeMake(headerSize.width, labelSize.height + QUESTION_VERTICAL_MARGIN + instructionsHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
	UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;
	return CGSizeMake(collectionView.bounds.size.width - sectionInset.left - sectionInset.right, 12.0);
}

#pragma mark - Text view delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	self.editingIndexPath = [NSIndexPath indexPathForItem:0 inSection:textView.tag];

	return YES;
}

- (void)textViewDidBeginEditing:(UITextField *)textView {
	[self.collectionView scrollToItemAtIndexPath:self.editingIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	self.editingIndexPath = nil;

	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:textView.tag];
	ATSurveyMultilineCell *cell = (ATSurveyMultilineCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
	cell.placeholderLabel.hidden = textView.text.length > 0;

	[self.collectionView performBatchUpdates:^{
		[self.viewModel setText:textView.text forAnswerAtIndexPath:indexPath];
		[self.collectionViewLayout invalidateLayout];
	} completion:nil];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	self.editingIndexPath = [NSIndexPath indexPathForItem:0 inSection:textField.tag];

	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self.collectionView scrollToItemAtIndexPath:self.editingIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
}

- (IBAction)textFieldChanged:(UITextField *)textField {
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:textField.tag];

	[self.viewModel setText:textField.text forAnswerAtIndexPath:indexPath];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	self.editingIndexPath = nil;

	[textField resignFirstResponder];

	return NO;
}

#pragma mark - View model delegate

- (void)viewModelValidationChanged:(ATSurveyViewModel *)viewModel {
	[self.collectionViewLayout invalidateLayout];
}

#pragma mark - Keyboard adjustment for iOS 7 & 8

- (void)adjustForKeyboard:(NSNotification *)notification {
	CGRect keyboardRect = [self.view.window convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.collectionView.superview];

	self.collectionView.contentInset = UIEdgeInsetsMake(self.collectionView.contentInset.top, self.collectionView.contentInset.left,  CGRectGetHeight(self.collectionView.bounds) - keyboardRect.origin.y, self.collectionView.contentInset.right);
}

@end
