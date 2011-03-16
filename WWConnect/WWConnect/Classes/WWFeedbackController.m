//
//  WWFeedbackController.m
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import "WWFeedbackController.h"


@interface WWFeedbackController (Private)
- (void)scrollToFirstResponder;
- (void)scrollToView:(UIView *)view;
- (BOOL)shouldReturn:(UIView *)view;
- (NSString *)feedbackFooterHTML;
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
    [submitCell release];
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

- (IBAction)submitFeedback:(id)sender {
    //TODO
    [self cancelFeedback:sender];
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    if (indexPath.section == kFeedbackFeedbackSection) {
        if (indexPath.row == kFeedbackFeedbackCell) {
            height = feedbackCell.frame.size.height;
        }
    }
    return height;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kFeedbackSectionCount;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    if (section == kFeedbackFeedbackSection) {
        return kFeedbackCellCount;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == kFeedbackFeedbackSection) {
        if (indexPath.row == kFeedbackFeedbackCell) {
            cell = feedbackCell;
        }
    }
    return cell;
}

#pragma mark UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self scrollToView:textView];
}

#pragma mark UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self scrollToView:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end


@implementation WWFeedbackController (Private)
- (void)scrollToFirstResponder {
    if (nameField.editing) {
        [self scrollToView:nameField];
    }
    if (phoneField.editing) {
        [self scrollToView:phoneField];
    }
    if (emailField.editing) {
        [self scrollToView:emailField];
    }
}

- (void)scrollToView:(UIView *)view {
    CGRect adjustedFrame = [view convertRect:view.bounds toView:tableView];
    adjustedFrame = CGRectInset(adjustedFrame, 0.0, 4.0);
    [tableView scrollRectToVisible:adjustedFrame animated:YES];
}

- (BOOL)shouldReturn:(UIView *)view {
    if (view == emailField || view == nameField) {
        UIView *next = emailField;
        if (view == emailField) {
            next = phoneField;
        }
        [next becomeFirstResponder];
    }
    return YES;
}

- (NSString *)feedbackFooterHTML {
    NSString *result = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"WWResources.bundle/ww_feedback_footer" ofType:@"html"];
    if (path) {
        result = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
    return result;
}

- (void)setup {
    NSString *html = [self feedbackFooterHTML];
    [footerWebView loadHTMLString:html baseURL:nil];
    tableView.delegate = self;
    tableView.dataSource = self;
    //tableView.tableFooterView = footerWebView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)teardown {
    [tableView release];
    tableView = nil;
    [feedbackCell release];
    feedbackCell = nil;
    [submitCell release];
    submitCell = nil;
    [footerWebView release];
    footerWebView = nil;
    [nameField release];
    nameField = nil;
    [phoneField release];
    phoneField = nil;
    [emailField release];
    emailField = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newFrame = tableView.frame;
    newFrame.size.height = keyboardTop - tableView.frame.origin.y;
    
    NSTimeInterval duration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:duration];
    tableView.frame = newFrame;
    [UIView commitAnimations];
    [self performSelector:@selector(scrollToFirstResponder) withObject:nil afterDelay:duration + 0.1];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    NSTimeInterval animationDuration;
    [(NSValue *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    tableView.frame = self.view.bounds;
    
    [UIView commitAnimations];
}
@end
