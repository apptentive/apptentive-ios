//
//  ATSurveyViewController.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyViewController.h"
#import "ATConnect.h"
#import "ATHUDView.h"
#import "ATRecordTask.h"
#import "ATSurvey.h"
#import "ATSurveysBackend.h"
#import "ATSurveyQuestion.h"
#import "ATSurveyResponse.h"
#import "ATSurveyTask.h"
#import "ATTaskQueue.h"

enum {
	kTextViewTag = 1
};

@interface ATSurveyViewController (Private)
- (void)cancel:(id)sender;

- (BOOL)sizeTextView:(ATCellTextView *)textView;

#pragma mark Rotation Handling

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;
@end

@implementation ATSurveyViewController

- (id)initWithSurvey:(ATSurvey *)aSurvey {
	if ((self = [super init])) {
		survey = [aSurvey retain];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
	[survey release], survey = nil;
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)sendSurvey {
	ATSurveyResponse *response = [[ATSurveyResponse alloc] init];
	response.identifier = survey.identifier;
	for (ATSurveyQuestion *question in [survey questions]) {
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
			answer.identifier = question.identifier;
			answer.response = question.answerText;
			[response addQuestionResponse:answer];
			[answer release], answer = nil;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			if (question.selectedAnswerChoice) {
				ATSurveyQuestionResponse *answer = [[ATSurveyQuestionResponse alloc] init];
				answer.identifier = question.identifier;
				answer.response = question.selectedAnswerChoice.identifier;
				[response addQuestionResponse:answer];
				[answer release], answer = nil;
			}
		}
	}
	ATRecordTask *task = [[ATRecordTask alloc] init];
	[task setRecord:response];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[response release], response = nil;
	[task release], task = nil;
	
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:self.view.window];
    hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting survey.");
    [hud show];
    [hud autorelease];

	[[ATSurveysBackend sharedBackend] resetSurvey];
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor whiteColor];
	tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;	
	[self.view addSubview:tableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
	
	self.title = ATLocalizedString(@"Survey", @"Survey view title");
	
	tableView.delegate = self;
	tableView.dataSource = self;
	[tableView reloadData];
	[self registerForKeyboardNotifications];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[tableView removeFromSuperview];
	tableView.delegate = nil;
	tableView.dataSource = nil;
	[tableView release], tableView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}
	 
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (activeTextView != nil) {
		
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return [[survey questions] count] + 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section < [[survey questions] count]) {
		ATSurveyQuestion *question = [[survey questions] objectAtIndex:section];
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			return 2;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			return [[question answerChoices] count] + 1;
		}
	} else if (section == [[survey questions] count]) {
		return 1;
	}
    return 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	ATCellTextView *textViewCell = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
	if (textViewCell != nil) {
		CGSize cellSize = CGSizeMake(textViewCell.bounds.size.width, textViewCell.bounds.size.height + 20);
		CGRect f = textViewCell.frame;
		f.origin.y = 10.0;
		textViewCell.frame = f;
		return MAX(44, cellSize.height);
	} else if (cell.textLabel.text != nil) {
		UIFont *font = cell.textLabel.font;
		CGSize cellSize = CGSizeMake(cell.textLabel.bounds.size.width, 1024);
		UILineBreakMode lbm = cell.textLabel.lineBreakMode;
		CGSize s = [cell.textLabel.text sizeWithFont:font constrainedToSize:cellSize lineBreakMode:lbm];
		CGRect f = cell.textLabel.frame;
		f.size = s;
		f.origin.y = 10;
		cell.textLabel.frame = f;
		return MAX(44, s.height + 20);
	} else {
		return 44;
	}
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ATSurveyCheckboxCellIdentifier = @"ATSurveyCheckboxCellIdentifier";
    static NSString *ATSurveyTextViewCellIdentifier = @"ATSurveyTextViewCellIdentifier";
    static NSString *ATSurveyQuestionCellIdentifier = @"ATSurveyQuestionCellIdentifier";
    static NSString *ATSurveySendCellIdentifier = @"ATSurveySendCellIdentifier";
	
	if (indexPath.section == [[survey questions] count]) {
		UITableViewCell *buttonCell = nil;
		buttonCell = [tableView dequeueReusableCellWithIdentifier:ATSurveySendCellIdentifier];
		if (!buttonCell) {
			buttonCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveySendCellIdentifier] autorelease];
			buttonCell.textLabel.text = ATLocalizedString(@"Send Response", @"Survey send response button title");
			buttonCell.textLabel.textAlignment = UITextAlignmentCenter;
			buttonCell.textLabel.textColor = [UIColor blueColor];
			buttonCell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		return buttonCell;
	} else if (indexPath.section >= [[survey questions] count]) {
		return nil;
	}
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:indexPath.section];
	UITableViewCell *cell = nil;
	if (indexPath.row == 0) {
		// Show the question row.
		cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyQuestionCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyQuestionCellIdentifier] autorelease];
			cell.textLabel.numberOfLines = 0;
			cell.textLabel.adjustsFontSizeToFitWidth = NO;
			cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
			cell.backgroundColor = [UIColor colorWithRed:223/255. green:235/255. blue:247/255. alpha:1.0];
		}
		cell.textLabel.text = question.questionText;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell layoutSubviews];
	} else {
		if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:indexPath.row - 1];
			// Make a checkbox cell.
			cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyCheckboxCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyCheckboxCellIdentifier] autorelease];
			}
			//cell.accessoryType = UITableViewCellAccessoryCheckmark;
			cell.textLabel.text = answer.value;
		} else {
			// Make a text entry cell.
			if (activeTextView != nil && activeTextEntryCell != nil && activeTextView.cellPath.row == indexPath.row && activeTextView.cellPath.section == indexPath.section) {
				cell = activeTextEntryCell;
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyTextViewCellIdentifier];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyTextViewCellIdentifier] autorelease];
					ATCellTextView *textView = [[ATCellTextView alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10.0, 10.0)];
					textView.font = [UIFont systemFontOfSize:16];
					textView.backgroundColor = [UIColor clearColor];
					textView.tag = kTextViewTag;
					textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
					[cell.contentView addSubview:textView];
					textView.returnKeyType = UIReturnKeyDone;
					[textView release], textView = nil;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
			}
			
			ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
			textView.cellPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
			textView.placeholder = @"Answer";
			textView.delegate = self;
			textView.question = question;
			if (question.answerText != nil) {
				textView.text = question.answerText;
			}
			//[textView sizeToFit];
			[self sizeTextView:textView];
			/*
			CGRect cellFrame = cell.frame;
			cellFrame.size.height = textView.frame.size.height + 20.0;
			cell.frame = cellFrame;
			 */
		}
	}
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == [[survey questions] count]) {
		[self sendSurvey];
	} else {
		ATSurveyQuestion *question = [[survey questions] objectAtIndex:indexPath.section];
		UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (indexPath.row == 0) {
			// Question row.
			
		} else {
			if (question.type == ATSurveyQuestionTypeMultipleChoice) {
				if (cell.accessoryType == UITableViewCellAccessoryNone) {
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
					ATSurveyQuestionAnswer *answer = [question.answerChoices objectAtIndex:indexPath.row - 1];
					question.selectedAnswerChoice = answer;
				} else {
					cell.accessoryType = UITableViewCellAccessoryNone;
					question.selectedAnswerChoice = nil;
				}
				// Deselect the other cells.
				UITableViewCell *otherCell = nil;
				for (NSUInteger i = 1; i < [self tableView:aTableView numberOfRowsInSection:indexPath.section]; i++) {
					if (i != indexPath.row) {
						NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:indexPath.section];
						otherCell = [aTableView cellForRowAtIndexPath:path];
						otherCell.accessoryType = UITableViewCellAccessoryNone;
					}
				}
			} else if (question.type == ATSurveyQuestionTypeSingeLine) {
				ATCellTextView *textView = (ATCellTextView *)[cell viewWithTag:kTextViewTag];
				[textView becomeFirstResponder];
			}
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if ([text isEqualToString:@"\n"]) {
		[textView resignFirstResponder];
		return NO;
	}
	return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ctv.question.answerText = ctv.text;
	}

	if ([self sizeTextView:(ATCellTextView *)textView]) {
		[tableView beginUpdates];
		[tableView endUpdates];
		[tableView scrollRectToVisible:CGRectInset(activeTextEntryCell.frame, 0, -10) animated:YES];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[textView flashScrollIndicators];
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
	activeTextView = (ATCellTextView *)[textView retain];
	activeTextEntryCell = [(UITableViewCell *)activeTextView.superview.superview retain];
	[tableView scrollRectToVisible:textView.superview.superview.frame animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if ([textView isKindOfClass:[ATCellTextView class]]) {
		ATCellTextView *ctv = (ATCellTextView *)textView;
		ctv.question.answerText = ctv.text;
	}
	[activeTextEntryCell release], activeTextEntryCell = nil;
	[activeTextView release], activeTextView = nil;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[textView resignFirstResponder];
	return YES;
}
@end

@implementation ATSurveyViewController (Private)

- (BOOL)sizeTextView:(ATCellTextView *)textView {
	BOOL didChange = NO;
	CGRect f = textView.frame;
	CGFloat originalHeight = f.size.height;
	CGSize maxSize = CGSizeMake(f.size.width, 150);
//	CGSize sizeThatFits = [textView.text sizeWithFont:textView.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
	CGSize sizeThatFits = [textView sizeThatFits:maxSize];
	if (originalHeight != sizeThatFits.height) {
		NSLog(@"old: %f, new: %f", originalHeight, sizeThatFits.height);
		f.size.height = sizeThatFits.height;
		textView.frame = f;
		didChange = YES;
	}
	return didChange;
}

- (void)cancel:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark Keyboard Handling
- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary* info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [tableView.window convertRect:kbFrame toView:tableView];
	CGSize kbSize = kbAdjustedFrame.size;
	
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    tableView.contentInset = contentInsets;
    tableView.scrollIndicatorInsets = contentInsets;
	
    // If active text field is hidden by keyboard, scroll it so it's visible
	if (activeTextView != nil && activeTextEntryCell) {
		CGRect aRect = tableView.frame;
		aRect.size.height -= kbSize.height;
		CGRect r = [activeTextEntryCell convertRect:activeTextView.frame toView:tableView];
		if (!CGRectContainsPoint(aRect, r.origin) ) {
			[activeTextView becomeFirstResponder];
			[tableView scrollRectToVisible:CGRectInset(activeTextEntryCell.frame, 0, -10) animated:YES];
//			CGPoint scrollPoint = CGPointMake(0.0, r.origin.y - kbSize.height);
//			[tableView setContentOffset:scrollPoint animated:YES];
		}
	}
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:[duration floatValue]];
	[UIView setAnimationCurve:[curve intValue]];
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    tableView.contentInset = contentInsets;
    tableView.scrollIndicatorInsets = contentInsets;
	[UIView commitAnimations];
}
@end

@implementation ATCellTextView
@synthesize cellPath, question;
- (void)dealloc {
	[cellPath release], cellPath = nil;
	[question release], question = nil;
	[super dealloc];
}
@end
