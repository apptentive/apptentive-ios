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
#import "ATSimpleImageViewController.h"

@interface ATFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)setupFeedback;
- (void)setupKeyboardAccessory;
- (void)teardown;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
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
    [feedbackView becomeFirstResponder];
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

- (IBAction)screenshotSwitchToggled:(id)sender {
    
}

- (IBAction)cancelFeedback:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)nextStep:(id)sender {
    // TODO
    feedback.type = [selectorControl currentSelection].feedbackType;
    feedback.text = feedbackView.text;
    if (!screenshotSwitch.on) {
        feedback.screenshot = nil;
    }
    
    ATContactInfoController *vc = [[ATContactInfoController alloc] init];
    vc.feedback = self.feedback;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

- (IBAction)imageDisclosureTapped:(id)sender {
    ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithImage:self.feedback.screenshot];
    vc.title = NSLocalizedString(@"Screenshot", @"Title for screenshot view.");
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactInfoChanged:) name:ATContactUpdaterFinished object:nil];
    feedbackView.placeholder = NSLocalizedString(@"Feedback", @"Placeholder text for user feedback field.");
    self.title = NSLocalizedString(@"Give Feedback", @"Title of feedback screen.");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Feedback", @"Title of back button which takes user back to feedback screen.") style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFeedback:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next Step", @"Title of button which takes user from feedback to contact info/screenshot screen.") style:UIBarButtonItemStyleBordered target:self action:@selector(nextStep:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    ATPopupSelection *feedbackSelection = [[ATPopupSelection alloc] initWithFeedbackType:ATFeedbackTypeFeedback popupImage:[ATBackend imageNamed:@"at_feedback"] selectedImage:[ATBackend imageNamed:@"at_feedback_selected"]];
    feedbackSelection.isSelected = YES;
    ATPopupSelection *smileySelection = [[ATPopupSelection alloc] initWithFeedbackType:ATFeedbackTypePraise popupImage:[ATBackend imageNamed:@"at_smiley"] selectedImage:[ATBackend imageNamed:@"at_smiley_selected"]];
    ATPopupSelection *frownySelection = [[ATPopupSelection alloc] initWithFeedbackType:ATFeedbackTypeBug popupImage:[ATBackend imageNamed:@"at_frowny"] selectedImage:[ATBackend imageNamed:@"at_frowny_selected"]];
    ATPopupSelection *questionSelection = [[ATPopupSelection alloc] initWithFeedbackType:ATFeedbackTypeQuestion popupImage:[ATBackend imageNamed:@"at_question"] selectedImage:[ATBackend imageNamed:@"at_question_selected"]];
    
    NSArray *selections = [NSArray arrayWithObjects:feedbackSelection, smileySelection, frownySelection, questionSelection, nil];
    selectorControl.selections = selections;
    [feedbackSelection release];
    [smileySelection release];
    [frownySelection release];
    [questionSelection release];
}

- (void)setupFeedback {
    if (feedbackView && [feedbackView isDefault] && feedback.text) {
        feedbackView.text = feedback.text;
    }
}

- (void)teardown {
    self.feedback = nil;
    [feedbackView release];
    feedbackView = nil;
    
    [screenshotContainerView release];
    screenshotContainerView = nil;
    
    [screenshotSwitch release];
    screenshotSwitch = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGRect)newFeedbackFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect feedbackRect = [feedbackView.superview convertRect:feedbackView.frame toView:nil];
    CGRect windowBounds = feedbackView.window.bounds;
    CGRect screenshotRect = screenshotContainerView.frame;
    CGFloat newHeight = windowBounds.size.height - keyboardRect.size.height - feedbackRect.origin.y - screenshotRect.size.height;
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = newHeight;
    
    return newFrame;
}

- (CGRect)newScreenshotFrameWithNotification:(NSNotification *)notification {
    CGRect newFeedbackFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect newScreenshotFrame = screenshotContainerView.frame;
    newScreenshotFrame.origin.y = newFeedbackFrame.origin.y + newFeedbackFrame.size.height;
    
    return newScreenshotFrame;
}

// Helper to get the frame of the feedbackView when a keyboard is shown.
- (void)keyboardWillShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect newScreenshotFrame = [self newScreenshotFrameWithNotification:notification];
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    feedbackView.frame = newFrame;
    screenshotContainerView.frame = newScreenshotFrame;
    [UIView commitAnimations];
    [feedbackView flashScrollIndicators];
}

// Need this on iPad, where modal dialogs are not layouted yet when
// when keyboardWillShow: is called.
- (void)keyboardDidShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect screenshotFrame = [self newScreenshotFrameWithNotification:notification];
    feedbackView.frame = newFrame;
    screenshotContainerView.frame = screenshotFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    CGRect viewRect = [feedbackView.superview.superview convertRect:feedbackView.superview.frame toView:nil];
    CGRect windowBounds = feedbackView.window.bounds;
    CGRect feedbackRect = [feedbackView.superview convertRect:feedbackView.frame toView:nil];
    CGRect screenshotRect = screenshotContainerView.frame;
    
    CGFloat bottomSpacing = windowBounds.size.height - (viewRect.origin.y + viewRect.size.height);
    CGFloat newHeight = windowBounds.size.height - feedbackRect.origin.y - bottomSpacing - screenshotRect.size.height;
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = newHeight;
    
    CGRect newScreenshotFrame = screenshotContainerView.frame;
    newScreenshotFrame.origin.y = newFrame.origin.y + newFrame.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    feedbackView.frame = newFrame;
    screenshotContainerView.frame = newScreenshotFrame;
    [UIView commitAnimations];
}

- (void)feedbackChanged:(NSNotification *)notification {
    if (notification.object == feedbackView) {
        self.navigationItem.rightBarButtonItem.enabled = ![@"" isEqualToString:feedbackView.text];
    }
}

- (void)contactInfoChanged:(NSNotification *)notification {
    ATContactStorage *contact = [ATContactStorage sharedContactStorage];
    if (contact.name) {
        feedback.name = contact.name;
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
        feedbackView.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
    }
}
@end
