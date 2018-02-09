//
//  ApptentiveSurveyViewController.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/22/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyViewController.h"
#import "ApptentiveSurveyAnswerCell.h"
#import "ApptentiveSurveyChoiceCell.h"
#import "ApptentiveSurveyCollectionViewLayout.h"
#import "ApptentiveSurveyGreetingView.h"
#import "ApptentiveSurveyMultilineCell.h"
#import "ApptentiveSurveyOtherCell.h"
#import "ApptentiveSurveyQuestionBackgroundView.h"
#import "ApptentiveSurveyQuestionFooterView.h"
#import "ApptentiveSurveyQuestionView.h"
#import "ApptentiveSurveySingleLineCell.h"
#import "ApptentiveSurveySubmitButton.h"
#import "ApptentiveSurveyViewModel.h"

#import "ApptentiveHUDViewController.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"

// These need to match the values from the storyboard
#define QUESTION_HORIZONTAL_MARGIN 52.0
#define QUESTION_VERTICAL_MARGIN 36.0

#define CHOICE_HORIZONTAL_MARGIN 70.0
#define CHOICE_VERTICAL_MARGIN 23.5

#define MULTILINE_HORIZONTAL_MARGIN 44
#define MULTILINE_VERTICAL_MARGIN 14

#define RANGE_VERTICAL_MARGIN 49
#define RANGE_FOOTER_VERTICAL_MARGIN 8
#define RANGE_MINIMUM_WIDTH 27

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyViewController ()

@property (strong, nonatomic) IBOutlet ApptentiveSurveyGreetingView *headerView;
@property (strong, nonatomic) IBOutlet UIView *headerBackgroundView;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UIView *footerBackgroundView;
@property (strong, nonatomic) IBOutlet ApptentiveSurveySubmitButton *submitButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *missingRequiredItem;

@property (nullable, strong, nonatomic) NSIndexPath *editingIndexPath;

@property (readonly, nonatomic) CGFloat lineHeightOfQuestionFont;
@property (assign, nonatomic) CGFloat toolbarInset;
@property (assign, nonatomic) BOOL keyboardVisible;

@end


@implementation ApptentiveSurveyViewController

- (void)viewDidLoad {
	[super viewDidLoad];

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromSafeArea;
	}
#endif

	self.collectionView.allowsMultipleSelection = YES;
	[self.collectionViewLayout registerClass:[ApptentiveSurveyQuestionBackgroundView class] forDecorationViewOfKind:@"QuestionBackground"];

	self.title = self.viewModel.title;

	self.headerView.greetingLabel.text = self.viewModel.greeting;
	[self.headerView.infoButton setImage:[ApptentiveUtilities imageNamed:@"at_info"] forState:UIControlStateNormal];
	self.headerView.infoButton.accessibilityLabel = ApptentiveLocalizedString(@"About Apptentive", @"Accessibility label for 'show about' button");
	[self.submitButton setTitle:self.viewModel.submitButtonText forState:UIControlStateNormal];

	((ApptentiveSurveyCollectionView *)self.collectionView).collectionHeaderView = self.headerView;
	((ApptentiveSurveyCollectionView *)self.collectionView).collectionFooterView = self.footerView;
	((ApptentiveSurveyCollectionViewLayout *)self.collectionViewLayout).shouldExpand = YES;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustForKeyboard:) name:UIKeyboardWillHideNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sizeDidUpdate:) name:UIContentSizeCategoryDidChangeNotification object:nil];

	id<ApptentiveStyle> style = self.viewModel.styleSheet;

	self.collectionView.backgroundColor = [style colorForStyle:ApptentiveColorCollectionBackground];
	self.headerBackgroundView.backgroundColor = [style colorForStyle:ApptentiveColorHeaderBackground];
	self.headerView.greetingLabel.font = [style fontForStyle:ApptentiveTextStyleHeaderMessage];
	self.headerView.greetingLabel.textColor = [style colorForStyle:ApptentiveTextStyleHeaderMessage];
	self.headerView.infoButton.tintColor = [style colorForStyle:ApptentiveTextStyleSurveyInstructions];
	self.headerView.borderView.backgroundColor = [style colorForStyle:ApptentiveColorSeparator];

	self.footerBackgroundView.backgroundColor = [style colorForStyle:ApptentiveColorFooterBackground];
	self.submitButton.titleLabel.font = [style fontForStyle:ApptentiveTextStyleSubmitButton];
	self.submitButton.backgroundColor = [style colorForStyle:ApptentiveColorBackground];

	self.missingRequiredItem.tintColor = [style colorForStyle:ApptentiveColorBackground];
	self.missingRequiredItem.title = [self.viewModel missingRequiredItemText];

	self.toolbarItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		self.missingRequiredItem,
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
													  target:nil
													  action:nil]];

	self.navigationController.toolbar.translucent = NO;
	self.navigationController.toolbar.barTintColor = [style colorForStyle:ApptentiveColorFailure];
	self.navigationController.toolbar.userInteractionEnabled = NO;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
		[self.collectionViewLayout invalidateLayout];
	} completion:nil];
}

- (void)sizeDidUpdate:(NSNotification *)notification {
	_lineHeightOfQuestionFont = 0;

	self.headerView.greetingLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleHeaderMessage];
	self.submitButton.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSubmitButton];

	[self.collectionView reloadData];
	[self.collectionViewLayout invalidateLayout];
}

- (IBAction)submit:(id)sender {
	[self.view endEditing:YES];

	if ([self.viewModel validate:YES]) {
		// Consider any pending edits complete
		if (self.editingIndexPath) {
			[self.viewModel commitChangeAtIndexPath:self.editingIndexPath];
		}

		[self.viewModel submit];

		UIViewController *presentingViewController = self.presentingViewController;
		[self dismissViewControllerAnimated:YES
								 completion:^{
								   [self.viewModel didSubmit:presentingViewController];
								 }];

		if (self.viewModel.showThankYou) {
			ApptentiveHUDViewController *HUD = [[ApptentiveHUDViewController alloc] init];
			[HUD showInAlertWindow];
			HUD.textLabel.text = self.viewModel.thankYouText;
			HUD.imageView.image = [ApptentiveUtilities imageNamed:@"at_thanks"];
		}
	} else {
		NSIndexPath *firstInvalidQuestionIndex = self.viewModel.firstInvalidAnswerIndexPath;
		ApptentiveAssertNotNil(firstInvalidQuestionIndex, @"Expected non-nil index");
		if (firstInvalidQuestionIndex) {
			[self.collectionView scrollToItemAtIndexPath:firstInvalidQuestionIndex atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
			UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [self.viewModel errorMessageAtIndex:firstInvalidQuestionIndex.section]);
		}
	}
}

- (IBAction)close:(id)sender {
	UIViewController *presentingViewController = self.presentingViewController;
	[self dismissViewControllerAnimated:YES
							 completion:^{
							   [self.viewModel didCancel:presentingViewController];
							 }];

	self.interactionController = nil;
}

- (IBAction)showAbout:(id)sender {
	[(ApptentiveNavigationController *)self.navigationController pushAboutApptentiveViewController];
}

- (void)setViewModel:(ApptentiveSurveyViewModel *)viewModel {
	_viewModel.delegate = nil;

	_viewModel = viewModel;

	viewModel.delegate = self;
}

@synthesize lineHeightOfQuestionFont = _lineHeightOfQuestionFont;

- (CGFloat)lineHeightOfQuestionFont {
	if (_lineHeightOfQuestionFont == 0) {
		UIFont *questionFont = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
		_lineHeightOfQuestionFont = CGRectGetHeight(CGRectIntegral([@"A" boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: questionFont } context:nil])) + CHOICE_VERTICAL_MARGIN;
	}

	return _lineHeightOfQuestionFont;
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
			ApptentiveSurveyMultilineCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MultilineText" forIndexPath:indexPath];

			cell.textView.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			cell.placeholderLabel.attributedText = [self.viewModel placeholderTextOfAnswerAtIndexPath:indexPath];
			cell.placeholderLabel.hidden = cell.textView.text.length > 0;
			cell.textView.delegate = self;
			cell.textView.tag = [self.viewModel textFieldTagForIndexPath:indexPath];
			cell.textView.accessibilityLabel = cell.placeholderLabel.text;
			cell.textView.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
			cell.textView.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleTextInput];

			return cell;
		}
		case ATSurveyQuestionTypeSingleLine: {
			ApptentiveSurveySingleLineCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SingleLineText" forIndexPath:indexPath];

			cell.textField.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
			cell.textField.attributedPlaceholder = [self.viewModel placeholderTextOfAnswerAtIndexPath:indexPath];
			cell.textField.delegate = self;
			cell.textField.tag = [self.viewModel textFieldTagForIndexPath:indexPath];
			cell.textField.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
			cell.textField.accessibilityLabel = cell.textField.placeholder;
			cell.textField.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleTextInput];

			return cell;
		}
		case ATSurveyQuestionTypeRange:
		case ATSurveyQuestionTypeSingleSelect:
		case ATSurveyQuestionTypeMultipleSelect: {
			NSString *reuseIdentifier, *buttonImageName, *detailText;
			NSString *accessibilityHintDetails = nil;

			switch ([self.viewModel typeOfQuestionAtIndex:indexPath.section]) {
				case ATSurveyQuestionTypeRange:
					if (indexPath.item == 0) {
						reuseIdentifier = @"RangeMinimum";
						detailText = [self.viewModel minimumLabelForQuestionAtIndex:indexPath.section];
						accessibilityHintDetails = [self.viewModel minimumLabelForQuestionAtIndex:indexPath.section];
					} else if (indexPath.item == [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section] - 1) {
						reuseIdentifier = @"RangeMaximum";
						detailText = [self.viewModel maximumLabelForQuestionAtIndex:indexPath.section];
						accessibilityHintDetails = [self.viewModel maximumLabelForQuestionAtIndex:indexPath.section];
					} else {
						reuseIdentifier = @"Range";
					}
					buttonImageName = @"at_circle";
					break;
				case ATSurveyQuestionTypeMultipleSelect:
					reuseIdentifier = @"Checkbox";
					buttonImageName = @"at_checkmark";
					break;
				default:
					reuseIdentifier = @"Radio";
					buttonImageName = @"at_circle";
					break;
			}

			UIImage *buttonImage = [[ApptentiveUtilities imageNamed:buttonImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			UIImage *highlightedButtonImage = [[ApptentiveUtilities imageNamed:[buttonImageName stringByAppendingString:@"_highlighted"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

			if ([self.viewModel typeOfAnswerAtIndexPath:indexPath] == ApptentiveSurveyAnswerTypeOther) {
				reuseIdentifier = [reuseIdentifier stringByAppendingString:@"Other"];
			}

			ApptentiveSurveyChoiceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

			cell.textLabel.text = [self.viewModel textOfChoiceAtIndexPath:indexPath];
			cell.textLabel.font = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
			cell.textLabel.textColor = [self.viewModel.styleSheet colorForStyle:UIFontTextStyleBody];

			cell.detailTextLabel.text = detailText;
			cell.detailTextLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
			cell.detailTextLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions];

			if (detailText) {
				cell.accessibilityHint = detailText;
			}

			if (accessibilityHintDetails.length > 0) {
				cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", accessibilityHintDetails, [self.viewModel textOfChoiceAtIndexPath:indexPath]];
			} else {
				cell.accessibilityLabel = [self.viewModel textOfChoiceAtIndexPath:indexPath];
			}
			cell.accessibilityTraits |= UIAccessibilityTraitButton;
			cell.button.image = buttonImage;
			cell.button.highlightedImage = highlightedButtonImage;
			[cell.button sizeToFit];

			cell.buttonTopConstraint.constant = (self.lineHeightOfQuestionFont - CGRectGetHeight(cell.button.bounds)) / 2.0;

			if ([self.viewModel typeOfAnswerAtIndexPath:indexPath] == ApptentiveSurveyAnswerTypeOther) {
				ApptentiveSurveyOtherCell *otherCell = (ApptentiveSurveyOtherCell *)cell;

				otherCell.validColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];
				otherCell.invalidColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorFailure];
				otherCell.valid = [self.viewModel answerIsValidAtIndexPath:indexPath];

				otherCell.textField.text = [self.viewModel textOfAnswerAtIndexPath:indexPath];
				otherCell.textField.attributedPlaceholder = [self.viewModel placeholderTextOfAnswerAtIndexPath:indexPath];
				otherCell.textField.delegate = self;
				otherCell.textField.tag = [self.viewModel textFieldTagForIndexPath:indexPath];
				otherCell.textField.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
				otherCell.textField.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleTextInput];
			}

			return cell;
		}
	}

	return nil;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	if (kind == UICollectionElementKindSectionHeader) {
		ApptentiveSurveyQuestionView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Question" forIndexPath:indexPath];

		view.textLabel.text = [self.viewModel textOfQuestionAtIndex:indexPath.section];
		view.textLabel.font = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
		view.textLabel.textColor = [self.viewModel.styleSheet colorForStyle:UIFontTextStyleBody];
		view.textLabel.accessibilityHint = [self.viewModel accessibilityHintForQuestionAtIndexPath:indexPath];
		view.instructionsTextLabel.attributedText = [self.viewModel instructionTextOfQuestionAtIndex:indexPath.section];
		view.instructionsTextLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];

		view.separatorView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];

		return view;
	} else {
		ApptentiveSurveyQuestionFooterView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];

		if ([self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeRange) {
			view.minimumLabel.text = [self.viewModel minimumLabelForQuestionAtIndex:indexPath.section];
			view.maximumLabel.text = [self.viewModel maximumLabelForQuestionAtIndex:indexPath.section];

			view.minimumLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
			view.maximumLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];

			view.minimumLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions];
			view.maximumLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions];
		} else {
			view.minimumLabel.text = nil;
			view.maximumLabel.text = nil;
		}

		return view;
	}
}

- (BOOL)sectionAtIndexIsValid:(NSInteger)index {
	return [self.viewModel answerIsValidForQuestionAtIndex:index];
}

- (UIColor *)validColor {
	return [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];
}

- (UIColor *)invalidColor {
	return [self.viewModel.styleSheet colorForStyle:ApptentiveColorFailure];
}

- (UIColor *)backgroundColor {
	return [self.viewModel.styleSheet colorForStyle:ApptentiveColorBackground];
}

#pragma mark Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.viewModel selectAnswerAtIndexPath:indexPath];

	[self maybeAnimateOtherSizeChangeAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	[self.viewModel deselectAnswerAtIndexPath:indexPath];

	[self maybeAnimateOtherSizeChangeAtIndexPath:indexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestionType questionType = [self.viewModel typeOfQuestionAtIndex:indexPath.section];

	return (questionType == ATSurveyQuestionTypeMultipleSelect || questionType == ATSurveyQuestionTypeSingleSelect || questionType == ATSurveyQuestionTypeRange);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestionType questionType = [self.viewModel typeOfQuestionAtIndex:indexPath.section];

	// Don't let them unselect the selected answer in a single select question
	if (questionType == ATSurveyQuestionTypeSingleSelect) {
		for (NSInteger answerIndex = 0; answerIndex < [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section]; answerIndex++) {
			if ([self.viewModel answerIsSelectedAtIndexPath:[NSIndexPath indexPathForItem:answerIndex inSection:indexPath.section]]) {
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

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		sectionInset.left += self.view.safeAreaInsets.left;
		sectionInset.right += self.view.safeAreaInsets.right;
	}
#endif

	CGSize itemSize = CGSizeMake(collectionView.bounds.size.width - sectionInset.left - sectionInset.right, 44.0);

	switch ([self.viewModel typeOfQuestionAtIndex:indexPath.section]) {
		case ATSurveyQuestionTypeSingleSelect:
		case ATSurveyQuestionTypeMultipleSelect: {
			CGFloat labelWidth = itemSize.width - CHOICE_HORIZONTAL_MARGIN;

			UIFont *choiceFont = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
			CGSize labelSize = CGRectIntegral([[self.viewModel textOfChoiceAtIndexPath:indexPath] boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: choiceFont } context:nil]).size;

			itemSize.height = labelSize.height + CHOICE_VERTICAL_MARGIN;

			if ([self.viewModel typeOfAnswerAtIndexPath:indexPath] == ApptentiveSurveyAnswerTypeOther && [self.viewModel answerIsSelectedAtIndexPath:indexPath]) {
				itemSize.height += 44.0;
			}

			if ([self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeRange) {
				itemSize.width = itemSize.width / [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section];
			}

			break;
		}
		case ATSurveyQuestionTypeRange: {
			NSInteger numberOfAnswers = [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section];
			NSString *firstChoice = [self.viewModel textOfChoiceAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
			NSString *lastChoice = [self.viewModel textOfChoiceAtIndexPath:[NSIndexPath indexPathForItem:numberOfAnswers - 1 inSection:indexPath.section]];

			UIFont *choiceFont = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
			CGSize firstLabelSize = CGRectIntegral([firstChoice boundingRectWithSize:CGSizeMake(itemSize.width, choiceFont.lineHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: choiceFont } context:nil]).size;
			CGSize lastLabelSize = CGRectIntegral([lastChoice boundingRectWithSize:CGSizeMake(itemSize.width, choiceFont.lineHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: choiceFont } context:nil]).size;

			CGSize largestSize = CGSizeMake(fmax(firstLabelSize.width, lastLabelSize.width), fmax(firstLabelSize.height, lastLabelSize.height));

			if (largestSize.width * numberOfAnswers > itemSize.width) {
				itemSize.width = largestSize.width;
			} else {
				itemSize.width = floor(itemSize.width / [self.viewModel numberOfAnswersForQuestionAtIndex:indexPath.section]);
			}

			itemSize.height = largestSize.height + RANGE_VERTICAL_MARGIN;

			if ([self.viewModel typeOfAnswerAtIndexPath:indexPath] == ApptentiveSurveyAnswerTypeOther && [self.viewModel answerIsSelectedAtIndexPath:indexPath]) {
				itemSize.height += 44.0;
			}

			if ([self.viewModel typeOfQuestionAtIndex:indexPath.section] == ATSurveyQuestionTypeRange) {
			}

			break;
		}
		case ATSurveyQuestionTypeSingleLine:
			itemSize.height = 44.0;
			break;
		case ATSurveyQuestionTypeMultipleLine: {
			CGFloat textViewWidth = itemSize.width - MULTILINE_HORIZONTAL_MARGIN;

			NSString *text = [[self.viewModel textOfAnswerAtIndexPath:indexPath] ?: @" " stringByAppendingString:@"\n"];
			UIFont *font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
			CGSize textSize = CGRectIntegral([text boundingRectWithSize:CGSizeMake(textViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: font } context:nil]).size;

			itemSize.height = fmax(textSize.height, 17.0) + MULTILINE_VERTICAL_MARGIN + 13;
			break;
		}
	}

	return itemSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
	UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)self.collectionViewLayout).sectionInset;

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		sectionInset.left += self.view.safeAreaInsets.left;
		sectionInset.right += self.view.safeAreaInsets.right;
	}
#endif

	CGFloat headerWidth = CGRectGetWidth(collectionView.bounds) - sectionInset.left - sectionInset.right;
	CGFloat labelWidth = headerWidth - QUESTION_HORIZONTAL_MARGIN;

	UIFont *questionFont = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
	CGSize labelSize = CGRectIntegral([[self.viewModel textOfQuestionAtIndex:section] boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: questionFont } context:nil]).size;

	NSString *instructionsText = [[self.viewModel instructionTextOfQuestionAtIndex:section] string];
	CGSize instructionsSize = CGSizeZero;
	if (instructionsText) {
		UIFont *instructionsFont = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
		instructionsSize = CGRectIntegral([instructionsText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: instructionsFont } context:nil]).size;
	}

	return CGSizeMake(headerWidth, labelSize.height + QUESTION_VERTICAL_MARGIN + instructionsSize.height);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
	UIEdgeInsets sectionInset = ((UICollectionViewFlowLayout *)collectionViewLayout).sectionInset;

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		sectionInset.left += self.view.safeAreaInsets.left;
		sectionInset.right += self.view.safeAreaInsets.right;
	}
#endif

	CGSize result = CGSizeMake(collectionView.bounds.size.width - sectionInset.left - sectionInset.right, 12.0);

	if ([self.viewModel typeOfQuestionAtIndex:section] == ATSurveyQuestionTypeRange) {
		if ([self.viewModel minimumLabelForQuestionAtIndex:section].length > 0 || [self.viewModel maximumLabelForQuestionAtIndex:section].length > 0) {
			UIFont *instructionsFont = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
			CGSize instructionsSize = CGRectIntegral([@"Tp" boundingRectWithSize:CGSizeMake(result.width / 2.0, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: instructionsFont } context:nil]).size;
			result.height = instructionsSize.height + RANGE_FOOTER_VERTICAL_MARGIN;
		} else {
			result.height = 8;
		}
	}

	return result;
}

#pragma mark - Text view delegate

- (void)textViewDidBeginEditing:(UITextField *)textView {
	self.editingIndexPath = [self.viewModel indexPathForTextFieldTag:textView.tag];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	self.editingIndexPath = nil;

	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	NSIndexPath *indexPath = [self.viewModel indexPathForTextFieldTag:textView.tag];
	ApptentiveSurveyMultilineCell *cell = (ApptentiveSurveyMultilineCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
	cell.placeholderLabel.hidden = textView.text.length > 0;

	[self.collectionView performBatchUpdates:^{
	  [self.viewModel setText:textView.text forAnswerAtIndexPath:indexPath];
	  CGPoint contentOffset = self.collectionView.contentOffset;
	  [self.collectionViewLayout invalidateLayout];
	  self.collectionView.contentOffset = contentOffset;
	} completion:nil];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self.viewModel commitChangeAtIndexPath:[self.viewModel indexPathForTextFieldTag:textView.tag]];
}

#pragma mark - Text field delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.editingIndexPath = [self.viewModel indexPathForTextFieldTag:textField.tag];
}

- (IBAction)textFieldChanged:(UITextField *)textField {
	NSIndexPath *indexPath = [self.viewModel indexPathForTextFieldTag:textField.tag];

	[self.viewModel setText:textField.text forAnswerAtIndexPath:indexPath];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	self.editingIndexPath = nil;

	[textField resignFirstResponder];

	return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self.viewModel commitChangeAtIndexPath:[self.viewModel indexPathForTextFieldTag:textField.tag]];
}

#pragma mark - View model delegate

- (void)viewModelValidationChanged:(ApptentiveSurveyViewModel *)viewModel isValid:(BOOL)valid {
	[self.collectionViewLayout invalidateLayout];

	[self setToolbarHidden:valid];

	for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
		if ([cell isKindOfClass:[ApptentiveSurveyOtherCell class]]) {
			ApptentiveSurveyOtherCell *otherCell = (ApptentiveSurveyOtherCell *)cell;
			otherCell.valid = [self.viewModel answerIsValidAtIndexPath:[self.viewModel indexPathForTextFieldTag:otherCell.textField.tag]];
		}
	}
}

- (void)viewModel:(ApptentiveSurveyViewModel *)viewModel didDeselectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.collectionView deselectItemAtIndexPath:indexPath animated:NO];

	[self maybeAnimateOtherSizeChangeAtIndexPath:indexPath];
}

// This gets called via the keyboard will hide/show notification, to:
// a) Collapse the space between the last question and the submit button on short surveys (they normally expand to fill the screen).
// b) Remove the toolbar inset added when the toolbar is hidden with the keyboard showing (see -setToolbarHidden: below).
- (void)adjustForKeyboard:(NSNotification *)notification {
	ApptentiveSurveyCollectionViewLayout *layout = (ApptentiveSurveyCollectionViewLayout *)self.collectionViewLayout;
	CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	self.keyboardVisible = CGRectGetMinY(keyboardRect) < CGRectGetMaxY(self.collectionView.frame);
	layout.shouldExpand = !self.keyboardVisible;

	CGFloat duration = ((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
	[UIView animateWithDuration:duration
					 animations:^{
						 // If the toolbar was hidden while the keyboard was visible, subtract off the toolbar height when the keyboard is hidden.
						 if (!self.keyboardVisible && self.toolbarInset > 0) {
							 UIEdgeInsets contentInset = self.collectionView.contentInset;
							 contentInset.bottom -= self.toolbarInset;
							 self.collectionView.contentInset = contentInset;
							 self.toolbarInset = 0;
						 }

						 [self.collectionView layoutIfNeeded];
					 }];
}

#pragma mark - Private

- (void)setToolbarHidden:(BOOL)hidden {
	if (hidden != self.navigationController.toolbarHidden) {
		CGFloat toolbarHeight = CGRectGetHeight(self.navigationController.toolbar.bounds);

		[self.navigationController setToolbarHidden:hidden animated:YES];

		// Workaround for bugs around showing/hiding opaque toolbar with keyboard visible
		[UIView animateWithDuration:0.2
						 animations:^{
							 CGPoint contentOffset = self.collectionView.contentOffset;
							 UIEdgeInsets insets = self.collectionView.contentInset;

							 if (self.keyboardVisible && hidden) {
								 // If we're hiding the toolbar with the keyboard visible, the OS will subtract content inset from the bottom, making it so the user can't scroll all the way down until the keyboard is hidden.

								 // Add back the toolbar height to the bottom content inset.
								 insets.bottom += toolbarHeight;
								 self.collectionView.contentInset = insets;

								 // Remember how much we content inset added so that we can subtract it if/when the keyboard is hidden.
								 self.toolbarInset = toolbarHeight;
							 }

							 // Scroll down to offset the OS's behavior
							 contentOffset.y += insets.bottom + toolbarHeight;
							 self.collectionView.contentOffset = contentOffset;
						 }];
	}
}

- (void)maybeAnimateOtherSizeChangeAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.viewModel typeOfAnswerAtIndexPath:indexPath] == ApptentiveSurveyAnswerTypeOther) {
		BOOL showing = [self.viewModel answerIsSelectedAtIndexPath:indexPath];
		[UIView animateWithDuration:0.25
			animations:^{
			  [self.collectionViewLayout invalidateLayout];
			}
			completion:^(BOOL finished) {
			  ApptentiveSurveyOtherCell *cell = (ApptentiveSurveyOtherCell *)[self.collectionView cellForItemAtIndexPath:indexPath];

			  if (showing) {
				  [cell.textField becomeFirstResponder];
				  cell.isAccessibilityElement = NO;
				  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell.textField);
			  } else {
				  [cell.textField resignFirstResponder];
				  cell.isAccessibilityElement = YES;
				  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, cell);
			  }
			}];
	}
}

@end

NS_ASSUME_NONNULL_END
