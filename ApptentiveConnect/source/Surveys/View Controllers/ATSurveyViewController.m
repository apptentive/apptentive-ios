//
//  ATSurveyViewController.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyViewController.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATHUDView.h"
#import "ATRecordTask.h"
#import "ATSurvey.h"
#import "ATSurveyMetrics.h"
#import "ATSurveyQuestion.h"
#import "ATSurveyResponse.h"
#import "ATSurveyResponseTask.h"
#import "ATTaskQueue.h"
#import "ATEngagementBackend.h"
#import "ATSurveyQuestionResponse.h"

#define DEBUG_CELL_HEIGHT_PROBLEM 0
#define kAssociatedQuestionKey ("associated_question")

NSString *const ATInteractionSurveyEventLabelCancel = @"cancel";

enum {
	kTextViewTag = 1,
	kTextFieldTag = 2
};


@interface ATSurveyViewController ()

@property (strong, nonatomic) ATSurvey *survey;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UITableViewCell *activeTextEntryCell;
@property (strong, nonatomic) ATCellTextView *activeTextView;
@property (strong, nonatomic) ATCellTextField *activeTextField;
@property (strong, nonatomic) NSMutableSet *sentNotificationsAboutQuestionIDs;
@property (strong, nonatomic) NSDate *startedSurveyDate;

- (void)textFieldChangedNotification:(NSNotification *)notification;
- (void)sendNotificationAboutTextQuestion:(ATSurveyQuestion *)question;
- (ATSurveyQuestion *)questionAtIndexPath:(NSIndexPath *)path;
- (BOOL)questionHasExtraInfo:(ATSurveyQuestion *)question;
- (BOOL)validateSurvey;
- (void)cancel:(id)sender;

- (BOOL)sizeTextView:(ATCellTextView *)textView;

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
@end


@implementation ATSurveyViewController

- (id)initWithSurvey:(ATSurvey *)aSurvey {
	if ((self = [super init])) {
		self.startedSurveyDate = [[NSDate alloc] init];

		self.survey = aSurvey;
		self.sentNotificationsAboutQuestionIDs = [[NSMutableSet alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChangedNotification:) name:UITextFieldTextDidChangeNotification object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	_tableView.delegate = nil;
	_tableView.dataSource = nil;
	_activeTextField.delegate = nil;
	_activeTextView.delegate = nil;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)sendSurvey {
	// Send text view notification, if applicable.
	if (self.activeTextView || self.activeTextField) {
		NSObject<ATCellTextEntry> *textEntry = self.activeTextView != nil ? self.activeTextView : self.activeTextField;
		NSString *text = textEntry.text;
		ATSurveyQuestion *question = textEntry.question;

		if (question) {
			question.answerText = text;
			[self sendNotificationAboutTextQuestion:question];
		}
	}

	ATSurveyResponse *response = (ATSurveyResponse *)[ATData newEntityNamed:@"ATSurveyResponse"];
	[response setup];
	response.pendingState = [NSNumber numberWithInt:ATPendingSurveyResponseStateSending];
	response.surveyID = self.survey.identifier;
	[response updateClientCreationTime];

	NSMutableDictionary *answers = [NSMutableDictionary dictionary];
	for (ATSurveyQuestion *question in [self.survey questions]) {
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
			answer.identifier = question.identifier;
			answer.response = question.answerText;

			if (answer.response) {
				answers[answer.identifier] = answer.response;
			}
			answer = nil;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			if ([question.selectedAnswerChoices count]) {
				ATSurveyQuestionAnswer *selectedAnswer = [question.selectedAnswerChoices objectAtIndex:0];
				ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
				answer.identifier = question.identifier;
				answer.response = selectedAnswer.identifier;

				if (answer.response) {
					answers[answer.identifier] = answer.response;
				}
				answer = nil;
			}
		} else if (question.type == ATSurveyQuestionTypeMultipleSelect) {
			if ([question.selectedAnswerChoices count]) {
				ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
				answer.identifier = question.identifier;
				NSMutableArray *responses = [NSMutableArray array];
				for (ATSurveyQuestionAnswer *selectedAnswer in question.selectedAnswerChoices) {
					[responses addObject:selectedAnswer.identifier];
				}
				answer.response = responses;

				if (answer.response) {
					answers[answer.identifier] = answer.response;
				}
				answer = nil;
			}
		}
	}
	[response setAnswers:answers];

	NSError *error = nil;
	if (![[[ATConnect sharedConnection].backend managedObjectContext] save:&error]) {
		ATLogError(@"Unable to send survey response: %@, error: %@", response, error);
		response = nil;
		return;
	}

	// Give it a wee bit o' delay.
	NSString *pendingSurveyResponseID = [response pendingSurveyResponseID];
	double delayInSeconds = 1.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		ATSurveyResponseTask *task = [[ATSurveyResponseTask alloc] init];
		task.pendingSurveyResponseID = pendingSurveyResponseID;
		[[ATTaskQueue sharedTaskQueue] addTask:task];
	});

	if (self.survey.showSuccessMessage && self.survey.successMessage) {
		UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting survey.") message:self.survey.successMessage delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil];
		[successAlert show];
	} else {
		ATHUDView *hud = [[ATHUDView alloc] initWithWindow:self.view.window];
		hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting survey.");
		hud.fadeOutDuration = 5.0;
		[hud show];
	}

	NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.survey.identifier ?: [NSNull null],
		ATSurveyWindowTypeKey: @(ATSurveyWindowTypeSurvey),
		ATSurveyMetricsEventKey: @(ATSurveyEventTappedSend),
		@"interaction_id": self.interaction.identifier ?: [NSNull null],
	};

	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidHideWindowNotification object:nil userInfo:metricsInfo];

	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];

	NSDictionary *notificationInfo = @{ATSurveyIDKey: (self.survey.identifier ?: [NSNull null])};
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveySentNotification object:nil userInfo:notificationInfo];

	response = nil;
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor whiteColor];
	self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.tableView];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	if (![self.survey responseIsRequired]) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	}

	self.title = ATLocalizedString(@"Survey", @"Survey view title");

	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	[self.tableView reloadData];
	[self registerForKeyboardNotifications];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.tableView removeFromSuperview];
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
	self.tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (self.activeTextView != nil) {
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
	return [[self.survey questions] count] + 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section < [[self.survey questions] count]) {
		NSUInteger result = 0;
		ATSurveyQuestion *question = [[self.survey questions] objectAtIndex:section];
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			result = 2;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			result = [[question answerChoices] count] + 1;
		}
		if ([self questionHasExtraInfo:question]) {
			result++;
		}
		return result;
	} else if (section == [[self.survey questions] count]) {
		return 1;
	}
	return 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
	ATCellTextView *textViewCell = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
	UITextField *textFieldCell = (UITextField *)[cell viewWithTag:kTextFieldTag];
	CGFloat cellHeight = 0;
	if (textViewCell != nil) {
		CGSize cellSize = CGSizeMake(textViewCell.bounds.size.width, textViewCell.bounds.size.height + 20);
		CGRect f = textViewCell.frame;
		f.origin.y = 10.0;
		textViewCell.frame = f;
		cellHeight = MAX(44, cellSize.height);
	} else if (textFieldCell != nil) {
		cellHeight = MAX(44, textFieldCell.bounds.size.height + 20);
	} else if (cell.textLabel.text != nil) {
		UIFont *font = cell.textLabel.font;

		if (indexPath.row == 0) {
			CGRect textFrame = cell.textLabel.frame;
			textFrame.size.width = cell.frame.size.width - 38.0;
			cell.textLabel.frame = textFrame;
#if DEBUG_CELL_HEIGHT_PROBLEM
			ATLogDebug(@"%@", NSStringFromCGRect(cell.textLabel.frame));
#endif
		}

		CGSize cellSize = CGSizeMake(cell.textLabel.bounds.size.width, 1024);
		NSLineBreakMode lbm = cell.textLabel.lineBreakMode;
		CGSize s = CGSizeZero;
		if ([cell.textLabel.text respondsToSelector:@selector(sizeWithAttributes:)]) {
			NSDictionary *attrs = @{NSFontAttributeName: font};
			NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cell.textLabel.text attributes:attrs];
			CGRect textSize = [attributedText boundingRectWithSize:cellSize options:NSStringDrawingUsesLineFragmentOrigin context:nil];
			s = textSize.size;
		} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			s = [cell.textLabel.text sizeWithFont:font constrainedToSize:cellSize lineBreakMode:lbm];
#pragma clang diagnostic pop
		}
		CGRect f = cell.textLabel.frame;
		f.size = s;
#if DEBUG_CELL_HEIGHT_PROBLEM
		if (s.height >= 50) {
			ATLogDebug(@"cell width is: %f", cell.frame.size.width);
			ATLogDebug(@"width is: %f", cellSize.width);
			ATLogDebug(@"Hi");
		}
#endif

		ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
		if (question != nil && indexPath.row == 1 && [self questionHasExtraInfo:question]) {
			f.origin.y = 4;
			cell.textLabel.frame = f;
			cellHeight = MAX(32, s.height + 8);
		} else {
			f.origin.y = 10;
			cell.textLabel.frame = f;
			cellHeight = MAX(44, s.height + 20);
		}
	} else {
		cellHeight = 44;
	}
	return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *ATSurveyExtraInfoCellIdentifier = @"ATSurveyExtraInfoCellIdentifier";
	static NSString *ATSurveyCheckboxCellIdentifier = @"ATSurveyCheckboxCellIdentifier";
	static NSString *ATSurveyTextViewCellIdentifier = @"ATSurveyTextViewCellIdentifier";
	static NSString *ATSurveyTextFieldCellIdentifier = @"ATSurveyTextFieldCellIdentifier";
	static NSString *ATSurveyQuestionCellIdentifier = @"ATSurveyQuestionCellIdentifier";
	static NSString *ATSurveySendCellIdentifier = @"ATSurveySendCellIdentifier";

	if (indexPath.section == [[self.survey questions] count]) {
		UITableViewCell *buttonCell = nil;
		buttonCell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveySendCellIdentifier];
		if (!buttonCell) {
			buttonCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveySendCellIdentifier];
			buttonCell.textLabel.text = ATLocalizedString(@"Send Response", @"Survey send response button title");
			buttonCell.textLabel.textAlignment = NSTextAlignmentCenter;
			if ([self.view respondsToSelector:@selector(tintColor)]) {
				buttonCell.textLabel.textColor = self.view.tintColor;
			}
			buttonCell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		return buttonCell;
	} else if (indexPath.section >= [[self.survey questions] count]) {
		return nil;
	}
	ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
	UITableViewCell *cell = nil;
	if (indexPath.row == 0) {
		// Show the question row.
		cell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveyQuestionCellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyQuestionCellIdentifier];
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
			cell.backgroundColor = [UIColor colorWithRed:223 / 255. green:235 / 255. blue:247 / 255. alpha:1.0];
#if DEBUG_CELL_HEIGHT_PROBLEM
			cell.textLabel.backgroundColor = [UIColor redColor];
#endif
			cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
		}
		cell.textLabel.text = question.questionText;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell layoutIfNeeded];
	} else if (indexPath.row == 1 && [self questionHasExtraInfo:question]) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveyExtraInfoCellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyExtraInfoCellIdentifier];
			cell.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.textLabel.font = [UIFont systemFontOfSize:15];
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
		}
		NSString *text = nil;
		if (question.instructionsText) {
			if ([question.instructionsText length]) {
				text = question.instructionsText;
			}
		} else if (question.responseIsRequired) {
			text = ATLocalizedString(@"required", @"Survey required answer fallback label.");
		}
		cell.textLabel.text = text;
		[cell layoutSubviews];
	} else {
		NSUInteger answerIndex = indexPath.row - 1;
		if ([self questionHasExtraInfo:question]) {
			answerIndex = answerIndex - 1;
		}

		if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
			ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:answerIndex];
			// Make a checkbox cell.
			cell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveyCheckboxCellIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyCheckboxCellIdentifier];
			}
			cell.textLabel.font = [UIFont systemFontOfSize:18];
			cell.textLabel.text = answer.value;
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
			if ([[question selectedAnswerChoices] containsObject:answer]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
			[cell layoutSubviews];
		} else if (question.type == ATSurveyQuestionTypeSingeLine && question.multiline) {
			// Make a text entry cell.
			if (self.activeTextView != nil && self.activeTextEntryCell != nil && self.activeTextView.cellPath.row == indexPath.row && self.activeTextView.cellPath.section == indexPath.section) {
				cell = self.activeTextEntryCell;
			} else {
				cell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveyTextViewCellIdentifier];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyTextViewCellIdentifier];
					ATCellTextView *textView = [[ATCellTextView alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10.0, 10.0)];
					textView.keyboardType = UIKeyboardTypeDefault;
					textView.font = [UIFont systemFontOfSize:16];
					textView.backgroundColor = [UIColor clearColor];
					textView.tag = kTextViewTag;
					textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
					textView.scrollEnabled = NO;
					[cell.contentView addSubview:textView];
					textView.returnKeyType = UIReturnKeyDefault;
					textView = nil;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
			}

			ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
			textView.cellPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
			textView.placeholder = ATLocalizedString(@"Answer", @"Answer label");
			textView.delegate = self;
			textView.question = question;
			if (question.answerText != nil) {
				textView.text = question.answerText;
			} else {
				textView.text = @"";
			}
			//[textView sizeToFit];
			[self sizeTextView:textView];
			/*
			 CGRect cellFrame = cell.frame;
			 cellFrame.size.height = textView.frame.size.height + 20.0;
			 cell.frame = cellFrame;
			 */
		} else if (question.type == ATSurveyQuestionTypeSingeLine && question.multiline == NO) {
			// Make a single-line text entry cell.
			if (self.activeTextField != nil && self.activeTextEntryCell != nil && self.activeTextField.cellPath.row == indexPath.row && self.activeTextField.cellPath.section == indexPath.section) {
				cell = self.activeTextEntryCell;
			} else {
				cell = [self.tableView dequeueReusableCellWithIdentifier:ATSurveyTextFieldCellIdentifier];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyTextFieldCellIdentifier];
					ATCellTextField *textField = [[ATCellTextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10, 10)];
					textField.font = [UIFont systemFontOfSize:16];
					textField.minimumFontSize = 8;
					textField.adjustsFontSizeToFitWidth = YES;
					textField.backgroundColor = [UIColor clearColor];
					textField.tag = kTextFieldTag;
					textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
					[cell.contentView addSubview:textField];
					textField.returnKeyType = UIReturnKeyDone;
					textField = nil;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
			}

			ATCellTextField *textField = (ATCellTextField *)[cell viewWithTag:kTextFieldTag];
			textField.cellPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
			textField.placeholder = ATLocalizedString(@"Answer", @"Answer label");
			textField.delegate = self;
			textField.question = question;
			if (question.answerText != nil) {
				textField.text = question.answerText;
			} else {
				textField.text = @"";
			}
		}
	}

	return cell;
}

#pragma mark UITableViewDelegate

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	if ([self.survey surveyDescription] != nil && section == 0) {
		return [self.survey surveyDescription];
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)aTableView titleForFooterInSection:(NSInteger)section {
	if (section == [[self.survey questions] count] && self.errorText != nil) {
		return self.errorText;
	}
	return nil;
}

- (void)scrollToBottom {
	if (self.tableView) {
		NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:[[self.survey questions] count]];
		[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == [[self.survey questions] count]) {
		if ([self validateSurvey]) {
			[self sendSurvey];
		} else {
			[self.tableView reloadData];
			[self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:0.1];
		}
	} else {
		ATSurveyQuestion *question = [self questionAtIndexPath:indexPath];
		UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (indexPath.row == 0) {
			// Question row.
		} else if ([self questionHasExtraInfo:question] && indexPath.row == 1) {
		} else {
			NSUInteger answerIndex = indexPath.row - 1;
			if ([self questionHasExtraInfo:question]) {
				answerIndex = answerIndex - 1;
			}
			if (question.type == ATSurveyQuestionTypeMultipleChoice || question.type == ATSurveyQuestionTypeMultipleSelect) {
				ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:answerIndex];
				BOOL isChecked = cell.accessoryType == UITableViewCellAccessoryCheckmark;

				NSUInteger maxSelections = question.maxSelectionCount;
				if (maxSelections == 0) {
					maxSelections = NSUIntegerMax;
				}

				BOOL deselectOtherAnswers = NO;

				if (isChecked) {
					// Tapping a previously selected answer unselects it.
					cell.accessoryType = UITableViewCellAccessoryNone;
					[question removeSelectedAnswerChoice:answer];
				} else if (!isChecked) {
					// Select the new answer and deselect previous answer.
					// A MultipleSelect with 1 max selection is essentially a MultipleChoice.
					if (question.type == ATSurveyQuestionTypeMultipleChoice || (question.type == ATSurveyQuestionTypeMultipleSelect && maxSelections == 1)) {
						cell.accessoryType = UITableViewCellAccessoryCheckmark;
						[question addSelectedAnswerChoice:answer];
						deselectOtherAnswers = YES;
					} else if (question.type == ATSurveyQuestionTypeMultipleSelect) {
						if (question.selectedAnswerChoices.count == maxSelections) {
							// Do nothing; maximum number of answers have already been selected.
							// Survey taker must manually deselect previous answers first.
						} else {
							cell.accessoryType = UITableViewCellAccessoryCheckmark;
							[question addSelectedAnswerChoice:answer];
							deselectOtherAnswers = NO;
						}
					}
				}

				// Deselect previous answers, if needed.
				if (deselectOtherAnswers) {
					UITableViewCell *otherCell = nil;
					for (NSUInteger i = 1; i < [self tableView:aTableView numberOfRowsInSection:indexPath.section]; i++) {
						if (i != indexPath.row) {
							NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
							otherCell = [aTableView cellForRowAtIndexPath:path];
							otherCell.accessoryType = UITableViewCellAccessoryNone;
						}
					}
				}

				// Send notification.
				NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.survey.identifier ?: [NSNull null],
					ATSurveyMetricsSurveyQuestionIDKey: question.identifier ?: [NSNull null],
					ATSurveyMetricsEventKey: @(ATSurveyEventAnsweredQuestion),
					@"interaction_id": self.interaction.identifier ?: [NSNull null],
				};

				[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidAnswerQuestionNotification object:nil userInfo:metricsInfo];

			} else if (question.type == ATSurveyQuestionTypeSingeLine) {
				ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
				[textView becomeFirstResponder];
			}
		}
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)text {
	if ([text isEqualToString:@"\n"]) {
		[textField resignFirstResponder];
		return NO;
	}
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.activeTextEntryCell = nil;
	self.activeTextView = nil;
	self.activeTextField = nil;

	self.activeTextField = (ATCellTextField *)textField;
	self.activeTextEntryCell = (UITableViewCell *)self.activeTextField.superview.superview;

	CGRect textEntryCellFrame = [self.tableView convertRect:self.activeTextEntryCell.frame fromView:self.activeTextEntryCell.superview];
	[self.tableView scrollRectToVisible:textEntryCellFrame animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if ([textField isKindOfClass:[ATCellTextField class]]) {
		ATCellTextField *ctf = (ATCellTextField *)textField;
		ATSurveyQuestion *question = ctf.question;

		if (question) {
			ctf.question.answerText = ctf.text;
			[self sendNotificationAboutTextQuestion:question];
		}
	}
	self.activeTextEntryCell = nil;
	self.activeTextField = nil;
}

- (void)textFieldChangedNotification:(NSNotification *)notification {
	if (self.activeTextField) {
		self.activeTextField.question.answerText = self.activeTextField.text;
	}
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ctv.question.answerText = ctv.text;
	}

	if ([self sizeTextView:(ATCellTextView *)textView]) {
		[self.tableView beginUpdates];
		[self.tableView endUpdates];
		CGRect textEntryCellFrame = [self.tableView convertRect:self.activeTextEntryCell.frame fromView:self.activeTextEntryCell.superview];
		[self.tableView scrollRectToVisible:CGRectInset(textEntryCellFrame, 0, -10) animated:YES];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[textView flashScrollIndicators];
	self.activeTextEntryCell = nil;
	self.activeTextView = nil;
	self.activeTextField = nil;

	self.activeTextView = (ATCellTextView *)textView;
	self.activeTextEntryCell = (UITableViewCell *)self.activeTextView.superview.superview;

	CGRect textEntryCellFrame = [self.tableView convertRect:self.activeTextEntryCell.frame fromView:self.activeTextEntryCell.superview];
	[self.tableView scrollRectToVisible:textEntryCellFrame animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ATSurveyQuestion *question = ctv.question;

		if (question) {
			ctv.question.answerText = ctv.text;
			[self sendNotificationAboutTextQuestion:question];
		}
	}
	self.activeTextEntryCell = nil;
	self.activeTextView = nil;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	return YES;
}

#pragma mark - Private methods

- (void)sendNotificationAboutTextQuestion:(ATSurveyQuestion *)question {
	if (!question.type == ATSurveyQuestionTypeSingeLine) {
		return;
	}

	// Send notification.
	if (![self.sentNotificationsAboutQuestionIDs containsObject:question.identifier]) {
		NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.survey.identifier ?: [NSNull null],
			ATSurveyMetricsSurveyQuestionIDKey: question.identifier ?: [NSNull null],
			ATSurveyMetricsEventKey: @(ATSurveyEventAnsweredQuestion),
			@"interaction_id": self.interaction.identifier ?: [NSNull null],
		};

		[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidAnswerQuestionNotification object:nil userInfo:metricsInfo];

		[self.sentNotificationsAboutQuestionIDs addObject:question.identifier];
	}
}


- (ATSurveyQuestion *)questionAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section >= [[self.survey questions] count]) {
		return nil;
	}
	return [[self.survey questions] objectAtIndex:indexPath.section];
}

- (BOOL)questionHasExtraInfo:(ATSurveyQuestion *)question {
	BOOL result = NO;
	if (question.responseIsRequired) {
		result = YES;
	} else if (question.type == ATSurveyQuestionTypeMultipleSelect) {
		result = YES;
	} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
		result = YES;
	}
	return result;
}

- (BOOL)validateSurvey {
	BOOL valid = YES;
	NSUInteger missingAnswerCount = 0;
	NSUInteger tooFewAnswersCount = 0;
	NSUInteger tooManyAnswersCount = 0;
	for (ATSurveyQuestion *question in [self.survey questions]) {
		ATSurveyQuestionValidationErrorType error = [question validateAnswer];
		if (error == ATSurveyQuestionValidationErrorMissingRequiredAnswer) {
			missingAnswerCount++;
			valid = NO;
		} else if (error == ATSurveyQuestionValidationErrorTooFewAnswers) {
			tooFewAnswersCount++;
			valid = NO;
		} else if (error == ATSurveyQuestionValidationErrorTooManyAnswers) {
			tooManyAnswersCount++;
			valid = NO;
		}
	}
	if (valid) {
		self.errorText = nil;
	} else {
		if (missingAnswerCount == 1) {
			self.errorText = ATLocalizedString(@"Missing a required answer.", @"Survey missing required answer label.");
		} else if (missingAnswerCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Missing %d required answers.", @"Survey missing required answers formatted label."), missingAnswerCount];
		} else if (tooFewAnswersCount == 1) {
			self.errorText = ATLocalizedString(@"Too few selections made for a question above.", @"Survey too few selections label.");
		} else if (tooFewAnswersCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Too few selections made for %d questions above.", @"Survey too few selections formatted label."), tooFewAnswersCount];
		} else if (tooManyAnswersCount == 1) {
			self.errorText = ATLocalizedString(@"Too many selections made for a question above.", @"Survey too many selections label.");
		} else if (tooManyAnswersCount > 1) {
			self.errorText = [NSString stringWithFormat:ATLocalizedString(@"Too many selections made for %d questions above.", @"Survey too many selections formatted label."), tooFewAnswersCount];
		}
	}
	return valid;
}

- (BOOL)sizeTextView:(ATCellTextView *)textView {
	BOOL didChange = NO;
	CGRect f = textView.frame;
	CGFloat originalHeight = f.size.height;
	CGSize maxSize = CGSizeMake(f.size.width, 150);
	//	CGSize sizeThatFits = [textView.text sizeWithFont:textView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
	CGSize sizeThatFits = [textView sizeThatFits:maxSize];
	sizeThatFits.height = MAX(55, sizeThatFits.height);
	if (originalHeight != sizeThatFits.height) {
		//		NSLog(@"old: %f, new: %f", originalHeight, sizeThatFits.height);
		f.size.height = sizeThatFits.height;
		textView.frame = f;
		didChange = YES;
	}
	return didChange;
}

- (void)cancel:(id)sender {
	NSDictionary *metricsInfo = @{ ATSurveyMetricsSurveyIDKey: self.survey.identifier ?: [NSNull null],
		ATSurveyWindowTypeKey: @(ATSurveyWindowTypeSurvey),
		ATSurveyMetricsEventKey: @(ATSurveyEventTappedCancel),
		@"interaction_id": self.interaction.identifier ?: [NSNull null],
	};

	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidHideWindowNotification object:nil userInfo:metricsInfo];

	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedRect = [self.view convertRect:kbFrame fromView:nil];

	UIScrollView *scrollView = self.tableView;
	CGRect scrollViewRect = [self.view convertRect:scrollView.frame fromView:scrollView.superview];

	CGRect occludedScrollViewRect = CGRectIntersection(scrollViewRect, kbAdjustedRect);
	if (!CGRectEqualToRect(CGRectZero, occludedScrollViewRect)) {
		UIEdgeInsets contentInsets = scrollView.contentInset;
		contentInsets.bottom = occludedScrollViewRect.size.height;
		scrollView.contentInset = contentInsets;
		scrollView.scrollIndicatorInsets = contentInsets;
	}

	// If active text field is hidden by keyboard, scroll it so it's visible
	if ((self.activeTextView != nil || self.activeTextField != nil) && self.activeTextEntryCell) {
		UIView<ATCellTextEntry> *entry = self.activeTextView != nil ? self.activeTextView : self.activeTextField;
		CGRect aRect = self.tableView.frame;
		aRect.size.height -= occludedScrollViewRect.size.height;
		CGRect r = [self.activeTextEntryCell convertRect:[entry frame] toView:self.tableView];
		if (!CGRectContainsPoint(aRect, r.origin)) {
			[entry becomeFirstResponder];

			CGRect textEntryCellFrame = [self.tableView convertRect:entry.frame fromView:entry.superview];
			[self.tableView scrollRectToVisible:CGRectInset(textEntryCellFrame, 0, -10) animated:YES];
		}
	}
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:[duration floatValue]];
	[UIView setAnimationCurve:[curve intValue]];
	UIEdgeInsets contentInsets = self.tableView.contentInset;
	contentInsets.bottom = 0;
	self.tableView.contentInset = contentInsets;
	self.tableView.scrollIndicatorInsets = contentInsets;
	[UIView commitAnimations];
}
@end


@implementation ATCellTextView
@end


@implementation ATCellTextField
@end
