//
//  ATFeedbackController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import "ATFeedbackController.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATContactInfoController.h"
#import "ATContactStorage.h"
#import "ATContactUpdater.h"
#import "ATDefaultTextView.h"
#import "ATFeedback.h"
#import "ATKeyboardAccessoryView.h"
#import "ATPopupSelectorControl.h"

@interface ATFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)setupFeedback;
- (void)setupKeyboardAccessory;
- (void)teardown;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)nameChanged:(NSNotification *)notification;
- (void)feedbackChanged:(NSNotification *)notification;
- (void)contactInfoChanged:(NSNotification *)notification;
@end

@implementation ATFeedbackController
@synthesize feedback;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATFeedbackController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATFeedbackController_iPad" bundle:[ATConnect resourceBundle]];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)setFeedback:(ATFeedback *)newFeedback {
    if (feedback != newFeedback) {
        [feedback release];
        feedback = nil;
        feedback = [newFeedback retain];
        [self setupFeedback];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    if (self.feedback.name) {
        [feedbackView becomeFirstResponder];
    } else {
        [nameField becomeFirstResponder];
    }
}

- (void)viewDidUnload {
    [self teardown];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return YES;
    } else {
        return NO;
    }
    //    return YES;
}

- (IBAction)cancelFeedback:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)nextStep:(id)sender {
    // TODO
    feedback.type = [selectorControl currentSelection].name;
    feedback.name = nameField.text;
    feedback.text = feedbackView.text;
    
    ATContactInfoController *vc = [[ATContactInfoController alloc] init];
    vc.feedback = self.feedback;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end


@implementation ATFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == nameField) {
        [feedbackView becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)setup {
    if (!feedback) {
        self.feedback = [[[ATFeedback alloc] init] autorelease];
    }
    [self setupFeedback];
    [self setupKeyboardAccessory];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackChanged:) name:UITextViewTextDidChangeNotification object:feedbackView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nameChanged:) name:UITextFieldTextDidChangeNotification object:nameField];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactInfoChanged:) name:ATContactUpdaterFinished object:nil];
    feedbackView.placeholder = NSLocalizedString(@"Feedback", @"Placeholder text for user feedback field.");
    self.title = NSLocalizedString(@"Give Feedback", @"Title of feedback screen.");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Feedback", @"Title of back button which takes user back to feedback screen.") style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFeedback:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next Step", @"Title of button which takes user from feedback to contact info/screenshot screen.") style:UIBarButtonItemStyleBordered target:self action:@selector(nextStep:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    ATPopupSelection *feedbackSelection = [[ATPopupSelection alloc] initWithName:@"feedback" popupImage:[ATBackend imageNamed:@"at_feedback"] selectedImage:[ATBackend imageNamed:@"at_feedback_selected"]];
    feedbackSelection.isSelected = YES;
    ATPopupSelection *smileySelection = [[ATPopupSelection alloc] initWithName:@"praise" popupImage:[ATBackend imageNamed:@"at_smiley"] selectedImage:[ATBackend imageNamed:@"at_smiley_selected"]];
    ATPopupSelection *frownySelection = [[ATPopupSelection alloc] initWithName:@"bug" popupImage:[ATBackend imageNamed:@"at_frowny"] selectedImage:[ATBackend imageNamed:@"at_frowny_selected"]];
    ATPopupSelection *questionSelection = [[ATPopupSelection alloc] initWithName:@"question" popupImage:[ATBackend imageNamed:@"at_question"] selectedImage:[ATBackend imageNamed:@"at_question_selected"]];
    
    NSArray *selections = [NSArray arrayWithObjects:feedbackSelection, smileySelection, frownySelection, questionSelection, nil];
    selectorControl.selections = selections;
    [feedbackSelection release];
    [smileySelection release];
    [frownySelection release];
    [questionSelection release];
}

- (void)setupFeedback {
    if (nameField && (!nameField.text || [@"" isEqualToString:nameField.text]) && feedback.name) {
        nameField.text = feedback.name;
    }
    if (feedbackView && [feedbackView isDefault] && feedback.text) {
        feedbackView.text = feedback.text;
    }
}

- (void)teardown {
    self.feedback = nil;
    [feedbackView release];
    feedbackView = nil;
    [nameField release];
    nameField = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGRect)newFeedbackFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect feedbackRect = [feedbackView.superview convertRect:feedbackView.frame toView:nil];
    CGRect windowBounds = feedbackView.window.bounds;
    CGFloat newHeight = windowBounds.size.height - keyboardRect.size.height - feedbackRect.origin.y;
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = newHeight;
    
    return newFrame;
}

// Helper to get the frame of the feedbackView when a keyboard is shown.
- (void)keyboardWillShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    feedbackView.frame = newFrame;
    [UIView commitAnimations];
    [feedbackView flashScrollIndicators];
}

// Need this on iPad, where modal dialogs are not layouted yet when
// when keyboardWillShow: is called.
- (void)keyboardDidShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    feedbackView.frame = newFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    CGRect viewRect = [feedbackView.superview.superview convertRect:feedbackView.superview.frame toView:nil];
    CGRect windowBounds = feedbackView.window.bounds;
    CGRect feedbackRect = [feedbackView.superview convertRect:feedbackView.frame toView:nil];
    
    CGFloat bottomSpacing = windowBounds.size.height - (viewRect.origin.y + viewRect.size.height);
    CGFloat newHeight = windowBounds.size.height - feedbackRect.origin.y - bottomSpacing;
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = newHeight;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    feedbackView.frame = newFrame;
    [UIView commitAnimations];
}

- (void)nameChanged:(NSNotification *)notification {
    if (notification.object == nameField) {
        nameIsDirtied = YES;
    }
}

- (void)feedbackChanged:(NSNotification *)notification {
    if (notification.object == feedbackView) {
        self.navigationItem.rightBarButtonItem.enabled = ![@"" isEqualToString:feedbackView.text];
    }
}

- (void)contactInfoChanged:(NSNotification *)notification {
    ATContactStorage *contact = [ATContactStorage sharedContactStorage];
    if (!nameIsDirtied && contact.name) {
        nameField.text = contact.name;
        [feedbackView becomeFirstResponder];
    }
    if (contact.phone) {
        feedback.phone = contact.phone;
    }
    if (contact.email) {
        feedback.email = contact.email;
    }
}

- (void)setupKeyboardAccessory {
    if ([[ATConnect sharedConnection] showKeyboardAccessory]) {
        nameField.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
        feedbackView.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
    }
}
@end
