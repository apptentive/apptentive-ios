//
//  ATSurveyViewController.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveyViewController.h"
#import "ATSurvey.h"
#import "ATSurveyQuestion.h"

enum {
	kTextFieldTag = 1
};

@interface ATSurveyViewController (Private)
- (void)cancel:(id)sender;

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
	[activeTextField release], activeTextField = nil;
	[survey release], survey = nil;
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
	
	self.title = @"Survey"; //!!
	
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
	if (activeTextField != nil) {
		
	}
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return [[survey questions] count];
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	if (section < [[survey questions] count]) {
		ATSurveyQuestion *question = [[survey questions] objectAtIndex:section];
		if (question.type == ATSurveyQuestionTypeSingeLine) {
			return 2;
		} else if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			return [[question answerChoices] count] + 1;
		}
	}
    return 0;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	if (cell.textLabel.text != nil) {
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
    static NSString *ATSurveyTextFieldCellIdentifier = @"ATSurveyTextFieldCellIdentifier";
    static NSString *ATSurveyQuestionCellIdentifier = @"ATSurveyQuestionCellIdentifier";
    
	
	if (indexPath.section >= [[survey questions] count]) {
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
			cell = [tableView dequeueReusableCellWithIdentifier:ATSurveyTextFieldCellIdentifier];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ATSurveyTextFieldCellIdentifier] autorelease];
				UITextField *textField = [[UITextField alloc] initWithFrame:CGRectInset(cell.contentView.bounds, 10.0, 10.0)];
				textField.tag = kTextFieldTag;
				textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				[cell.contentView addSubview:textField];
				textField.returnKeyType = UIReturnKeyDone;
				[textField release], textField = nil;
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			
			UITextField *textField = (UITextField *)[cell viewWithTag:kTextFieldTag];
			textField.placeholder = @"Answer";
			textField.delegate = self;
		}
	}
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:indexPath.section];
	UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
	if (indexPath.row == 0) {
		// Question row.

	} else {
		if (question.type == ATSurveyQuestionTypeMultipleChoice) {
			if (cell.accessoryType == UITableViewCellAccessoryNone) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			} else {
				cell.accessoryType = UITableViewCellAccessoryNone;
			}
		} else {
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[activeTextField release], activeTextField = nil;
	activeTextField = [textField retain];
	[tableView scrollRectToVisible:textField.superview.superview.frame animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[activeTextField release], activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}
@end

@implementation ATSurveyViewController (Private)
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
	if (activeTextField != nil) {
		CGRect aRect = tableView.frame;
		aRect.size.height -= kbSize.height;
		CGRect r = [activeTextField.superview.superview convertRect:activeTextField.frame toView:tableView];
		if (!CGRectContainsPoint(aRect, r.origin) ) {
			[activeTextField becomeFirstResponder];
			[tableView scrollRectToVisible:activeTextField.superview.superview.frame animated:YES];
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
