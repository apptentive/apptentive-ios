//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "ATMessageCenterViewController.h"
#import "ATBackend.h"
#import "ATConnect.h"

#define TextViewPadding 4

@interface ATMessageCenterViewController ()
- (void)styleTextView;
- (CGRect)formRectToShow;
- (void)registerForKeyboardNotifications;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
@end

@implementation ATMessageCenterViewController {
	BOOL attachmentsVisible;
	CGRect currentKeyboardFrameInView;
	CGFloat composerFieldHeight;
}
@synthesize tableView, containerView, composerView, composerBackgroundView, attachmentButton, textView, sendButton, attachmentView;

- (id)init {
	self = [super initWithNibName:@"ATMessageCenterViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self registerForKeyboardNotifications];
	self.title = ATLocalizedString(@"Message Center", @"Message Center title");
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];
	[self styleTextView];
	
	self.composerBackgroundView.image = [[ATBackend imageNamed:@"at_inbox_composer_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 0, 29, 19)];
	
	[self.view addSubview:self.containerView];
	
	composerFieldHeight = self.composerView.frame.size.height;
	
	
	UIImage *sendImage = [[ATBackend imageNamed:@"at_send_button_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
	[self.sendButton setBackgroundImage:sendImage forState:UIControlStateNormal];
	[self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.sendButton.titleLabel setShadowOffset:CGSizeMake(0, -1)];
	[self.sendButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.4] forState:UIControlStateDisabled];
}

- (void)viewDidLayoutSubviews {
	CGFloat viewHeight = self.view.bounds.size.height;
	NSLog(@"frame size: %@", NSStringFromCGRect(self.view.frame));
	
	CGRect composerFrame = composerView.frame;
	CGRect tableFrame = tableView.frame;
	CGRect containerFrame = containerView.frame;
	CGRect attachmentFrame = attachmentView.frame;

	composerFrame.size.height = composerFieldHeight + 2*TextViewPadding;
	
	if (!attachmentsVisible) {
		composerFrame.origin.y = viewHeight - composerView.frame.size.height;
	} else {
		composerFrame.origin.y = viewHeight - composerView.frame.size.height - attachmentFrame.size.height;
	}
	
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		CGFloat bottomOffset = viewHeight - composerFrame.size.height;
		CGFloat keyboardOffset = currentKeyboardFrameInView.origin.y - composerFrame.size.height;
		if (attachmentsVisible) {
			bottomOffset = bottomOffset - attachmentFrame.size.height;
			keyboardOffset = keyboardOffset - attachmentFrame.size.height;
		}
		composerFrame.origin.y = MIN(bottomOffset, keyboardOffset);
	}
	
	tableFrame.origin.y = 0;
	tableFrame.size.height = composerFrame.origin.y;
	containerFrame.size.height = composerFrame.size.height + tableFrame.size.height + attachmentFrame.size.height;
	attachmentFrame.origin.y = composerFrame.origin.y + composerFrame.size.height;
	
	containerView.frame = containerFrame;
	[containerView setNeedsLayout];
	tableView.frame = tableFrame;
	composerView.frame = composerFrame;
	attachmentView.frame = attachmentFrame;
	
	if (!CGRectEqualToRect(composerFrame, composerView.frame)) {
		NSLog(@"composerFrame: %@ != %@", NSStringFromCGRect(composerFrame), NSStringFromCGRect(composerView.frame));
	}
	if (!CGRectEqualToRect(attachmentFrame, attachmentView.frame)) {
		NSLog(@"attachmentFrame: %@ != %@", NSStringFromCGRect(attachmentFrame), NSStringFromCGRect(attachmentView.frame));
	}
	if (!CGRectEqualToRect(containerFrame, containerView.frame)) {
		NSLog(@"containerFrame: %@ != %@", NSStringFromCGRect(containerFrame), NSStringFromCGRect(containerView.frame));
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[tableView release];
	[attachmentView release];
	[containerView release];
	[composerView release];
	[composerBackgroundView release];
	[textView release];
	[sendButton release];
	[attachmentButton release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTableView:nil];
	[self setAttachmentView:nil];
	[self setContainerView:nil];
	[self setComposerView:nil];
	[self setComposerBackgroundView:nil];
	[self setTextView:nil];
	[self setSendButton:nil];
	[self setAttachmentButton:nil];
	[super viewDidUnload];
}

- (IBAction)donePressed:(id)sender {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)sendPressed:(id)sender {
}

- (IBAction)paperclipPressed:(id)sender {
	attachmentsVisible = !attachmentsVisible;
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		[self.textView resignFirstResponder];
	} else {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3];
		[self viewDidLayoutSubviews];
		[UIView commitAnimations];
	}
}

#pragma mark Private
- (void)styleTextView {
	self.textView.placeholder = @"What's on your mind?";
	self.textView.clipsToBounds = YES;
	self.textView.font = [UIFont systemFontOfSize:13];
}

#pragma mark UITextViewDelegate
- (void)resizingTextView:(ATResizingTextView *)textView willChangeHeight:(CGFloat)height {
	composerFieldHeight = height;
	[self viewDidLayoutSubviews];
}

- (void)resizingTextView:(ATResizingTextView *)textView didChangeHeight:(CGFloat)height {
	[self viewDidLayoutSubviews];
}

- (BOOL)resizingTextViewShouldBeginEditing:(ATResizingTextView *)textView {
	return YES;
}

#pragma mark Keyboard Handling
- (CGRect)formRectToShow {
	CGRect result = self.composerView.frame;
	return result;
}

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	attachmentsVisible = NO;
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.view.window convertRect:kbFrame toView:self.view];
	
	currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
	[self viewDidLayoutSubviews];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:[duration floatValue]];
	[UIView setAnimationCurve:[curve intValue]];
	currentKeyboardFrameInView = CGRectZero;
	[self viewDidLayoutSubviews];
	[UIView commitAnimations];
}
@end
