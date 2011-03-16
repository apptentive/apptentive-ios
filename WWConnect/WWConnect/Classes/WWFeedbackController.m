//
//  WWFeedbackController.m
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import "WWFeedbackController.h"
#import "ATDefaultTextView.h"


@interface WWFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)teardown;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
@end

@implementation WWFeedbackController

- (id)init {
    self = [self initWithNibName:@"WWFeedbackController" bundle:nil];
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

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [nameField becomeFirstResponder];
}

- (void)viewDidUnload {
    [self teardown];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (IBAction)cancelFeedback:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)nextStep:(id)sender {
    // TODO
    [self cancelFeedback:sender];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end


@implementation WWFeedbackController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == nameField) {
        [feedbackView becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)setup {
    NSLog(@"navigationController: %@", self.navigationController);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nameChanged:) name:UITextFieldTextDidChangeNotification object:nameField];
    nextButton.enabled = NO;
    feedbackView.placeholder = NSLocalizedString(@"Feedback (optional)", nil);
}

- (void)teardown {
    [feedbackView release];
    feedbackView = nil;
    [nameField release];
    nameField = nil;
    [nextButton release];
    nextButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newFrame = feedbackView.frame;
    newFrame.size.height = keyboardTop - feedbackView.frame.origin.y;
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    feedbackView.frame = newFrame;
    [UIView commitAnimations];
    [feedbackView flashScrollIndicators];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    feedbackView.frame = self.view.bounds;
    
    [UIView commitAnimations];
}

- (void)nameChanged:(NSNotification *)notification {
    if (notification.object == nameField) {
        nextButton.enabled = ![@"" isEqualToString:nameField.text];
    }
}
@end
