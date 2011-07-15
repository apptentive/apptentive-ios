//
//  ATSimpleFeedbackController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/13/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATSimpleFeedbackController.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATContactInfoController.h"
#import "ATContactStorage.h"
#import "ATContactUpdater.h"
#import "ATDefaultTextView.h"
#import "ATFeedback.h"
#import "ATHUDView.h"
#import "ATInfoViewController.h"
#import "ATKeyboardAccessoryView.h"

#define kATEmailAlertTextFieldTag 1010

@interface ATSimpleFeedbackController (Private)
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
- (void)captureFeedbackState;
- (void)sendFeedbackAndDismiss;
@end

@implementation ATSimpleFeedbackController
@synthesize feedback, customPlaceholderText;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATSimpleFeedbackController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATSimpleFeedbackController" bundle:[ATConnect resourceBundle]];
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [feedbackView becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    UIDevice *device = [UIDevice currentDevice];
    if ([device userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        // Not enough space to lay out fields on the iPhone in landscape.
        if (interfaceOrientation == UIInterfaceOrientationPortrait) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (IBAction)cancelFeedback:(id)sender {
    [self captureFeedbackState];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)nextStep:(id)sender {
    [self captureFeedbackState];
    
    if (!self.feedback.email || [self.feedback.email length] == 0) {
        NSString *title = NSLocalizedString(@"No email address?", @"Lack of email dialog title.");
        NSString *message = NSLocalizedString(@"We can't respond without one.\n\n\n", @"Lack of email dialog message.");
        UIAlertView *emailAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil  otherButtonTitles:NSLocalizedString(@"Send Feedback", @"Send button title"), nil];
        
        UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(16, 83, 252, 25)];
        field.font = [UIFont systemFontOfSize:18];
        field.backgroundColor = [UIColor clearColor];
        field.keyboardAppearance = UIKeyboardAppearanceAlert;
        field.delegate = self;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.placeholder = NSLocalizedString(@"Email Address", @"Email address popup placeholder text.");
        field.borderStyle = UITextBorderStyleRoundedRect;
        field.tag = kATEmailAlertTextFieldTag;
        [field becomeFirstResponder];
        [emailAlert addSubview:field];
        [field release], field = nil;
        [emailAlert sizeToFit];
        [emailAlert show];
        [emailAlert release];
    } else {
        [self sendFeedbackAndDismiss];
    }
}

- (IBAction)showInfoView:(id)sender {
    ATInfoViewController *vc = [[ATInfoViewController alloc] init];
    [self presentModalViewController:vc animated:YES];
    [vc release];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    UITextField *textField = (UITextField *)[alertView viewWithTag:kATEmailAlertTextFieldTag];
    if (textField) {
        self.feedback.email = textField.text;
        [self sendFeedbackAndDismiss];
    }
}
@end


@implementation ATSimpleFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == feedbackView) {
        [emailField becomeFirstResponder];
        return NO;
    } else if (view == emailField) {
        if (feedbackView.text && [feedbackView.text length] != 0) {
            [self nextStep:emailField];
            return YES;
        } else {
            [feedbackView becomeFirstResponder];
            return NO;
        }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactInfoChanged:) name:ATContactUpdaterFinished object:nil];
	
    if (self.customPlaceholderText) {
        feedbackView.placeholder = self.customPlaceholderText;
    } else {
        feedbackView.placeholder = ATLocalizedString(@"Feedback", nil);
    }
    self.title = ATLocalizedString(@"Give Feedback", @"Title of feedback screen.");
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:ATLocalizedString(@"Feedback", nil) style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelFeedback:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:ATLocalizedString(@"Submit", @"Label of button for submitting feedback.") style:UIBarButtonItemStyleDone target:self action:@selector(nextStep:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = ![@"" isEqualToString:feedbackView.text];
}

- (void)setupFeedback {
    if (feedbackView && [feedbackView isDefault] && feedback.text) {
        feedbackView.text = feedback.text;
    }
    if (emailField && (!emailField.text || [@"" isEqualToString:emailField.text]) && feedback.email) {
        emailField.text = feedback.email;
    }
}

- (void)teardown {
    self.feedback = nil;
    self.customPlaceholderText = nil;
    [feedbackView release];
    feedbackView = nil;
    
    [emailContainerView release], emailContainerView = nil;
    
    [emailField release], emailField = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGRect)newFeedbackFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    UIWindow *window = feedbackView.window;
    CGRect newFrame = CGRectZero;
    
    // We want to work with everything relative to the feedbackView.
    // Let's get keyboard frame in coordinates we can deal with:
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]; // screen
    CGRect keyboardFrameWindowRelative = [window convertRect:keyboardFrame fromWindow:nil]; // window
    CGRect keyboardFrameFeedbackRelative = [feedbackView convertRect:keyboardFrameWindowRelative fromView:nil]; // feedbackView
    // Superview frame.
    CGRect superviewFrameFeedbackRelative = [feedbackView.superview convertRect:feedbackView.superview.frame toView:feedbackView]; // feedbackView
    
    // And, of course, the feedbackView frame.
    CGRect feedbackViewFrame = [feedbackView.superview convertRect:feedbackView.frame toView:feedbackView]; // feedbackView
    
    // Okay, what's the amount of space we have left over for the feedbackView?
    CGFloat emailViewHeight = emailContainerView.frame.size.height;
    
    CGFloat keyboardOrigin = keyboardFrameFeedbackRelative.origin.y;
    CGFloat superviewBottom = superviewFrameFeedbackRelative.origin.y + superviewFrameFeedbackRelative.size.height;
    
    CGFloat maxYForFeedbackView = MIN(keyboardOrigin, superviewBottom);
    CGFloat newFeedbackViewHeight = maxYForFeedbackView - emailViewHeight;
    
    CGRect newFrameFeedbackRelative = CGRectZero;
    newFrameFeedbackRelative.origin.y = feedbackViewFrame.origin.y;
    newFrameFeedbackRelative.origin.x = feedbackViewFrame.origin.x;
    newFrameFeedbackRelative.size.width = feedbackViewFrame.size.width;
    newFrameFeedbackRelative.size.height = newFeedbackViewHeight;
    
    newFrame = [feedbackView.superview convertRect:newFrameFeedbackRelative fromView:feedbackView];
    
    return newFrame;
}

- (CGRect)newEmailFrameWithNotification:(NSNotification *)notification {
    CGRect newFeedbackFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect newEmailFrame = emailContainerView.frame;
    newEmailFrame.origin.y = newFeedbackFrame.origin.y + newFeedbackFrame.size.height;
    
    return newEmailFrame;
}

// Helper to get the frame of the feedbackView when a keyboard is shown.
- (void)keyboardWillShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect newEmailFrame = [self newEmailFrameWithNotification:notification];
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    feedbackView.frame = newFrame;
    emailContainerView.frame = newEmailFrame;
    [UIView commitAnimations];
    [feedbackView flashScrollIndicators];
}

// Need this on iPad, where modal dialogs are not layouted yet when
// when keyboardWillShow: is called.
- (void)keyboardDidShow:(NSNotification *)notification {
    if (!feedbackView.window) return;
    CGRect newFrame = [self newFeedbackFrameWithNotification:notification];
    CGRect emailFrame = [self newEmailFrameWithNotification:notification];
    feedbackView.frame = newFrame;
    emailContainerView.frame = emailFrame;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!feedbackView.window) return;
    
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    CGRect viewRect = [feedbackView.superview.superview convertRect:feedbackView.superview.frame toView:nil];
    CGRect windowBounds = feedbackView.window.bounds;
    CGRect feedbackRect = [feedbackView.superview convertRect:feedbackView.frame toView:nil];
    CGRect emailRect = emailContainerView.frame;
    
    CGFloat bottomSpacing = windowBounds.size.height - (viewRect.origin.y + viewRect.size.height);
    CGFloat newHeight = windowBounds.size.height - feedbackRect.origin.y - bottomSpacing - emailRect.size.height;
    
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = newHeight;
    
    CGRect newEmailFrame = emailContainerView.frame;
    newEmailFrame.origin.y = newFrame.origin.y + newFrame.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    feedbackView.frame = newFrame;
    emailContainerView.frame = newEmailFrame;
    [UIView commitAnimations];
}

- (void)feedbackChanged:(NSNotification *)notification {
    if (notification.object == feedbackView) {
        BOOL empty = [@"" isEqualToString:feedbackView.text];
        self.navigationItem.rightBarButtonItem.enabled = !empty;
        emailField.returnKeyType = empty ? UIReturnKeyNext : UIReturnKeyDone;
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
        NSArray *textFields = [NSArray arrayWithObjects:feedbackView, emailField, nil];
        for (UITextField *textField in textFields) {
            ATKeyboardAccessoryView *accessory = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
            [accessory addTarget:self action:@selector(showInfoView:) forControlEvents:UIControlEventTouchUpInside];
            textField.inputAccessoryView = accessory;
        }
    }
}

- (void)captureFeedbackState {
    feedback.text = feedbackView.text;
    feedback.email = emailField.text;
}

- (void)sendFeedbackAndDismiss {
    self.feedback.screenshot = nil; // enforce no screenshot
    [[ATBackend sharedBackend] sendFeedback:feedback];
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:[[self view] window]];
    hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting feedback.");
    [hud show];
    [hud autorelease];
    [self dismissModalViewControllerAnimated:YES];
}
@end

