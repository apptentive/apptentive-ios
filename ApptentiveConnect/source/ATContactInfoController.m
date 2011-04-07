//
//  ATContactInfoController.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATContactInfoController.h"
#import <QuartzCore/QuartzCore.h>
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATFeedback.h"
#import "ATHUDView.h"
#import "ATKeyboardAccessoryView.h"
#import "ATUtilities.h"

@interface ATContactInfoController (Private)
- (BOOL)shouldReturn:(UIView *)view;
- (void)setup;
- (void)setupFeedback;
- (void)setupKeyboardAccessory;
- (void)teardown;
@end

@implementation ATContactInfoController
@synthesize feedback;

- (id)init {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self = [super initWithNibName:@"ATContactInfoController" bundle:[ATConnect resourceBundle]];
    } else {
        self = [super initWithNibName:@"ATContactInfoController_iPad" bundle:[ATConnect resourceBundle]];
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
    [nameField becomeFirstResponder];
}

- (void)viewDidUnload {
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


- (IBAction)nextStep:(id)sender {
    feedback.name = nameField.text;
    feedback.email = emailField.text;
    feedback.phone = phoneField.text;
    [[ATBackend sharedBackend] sendFeedback:feedback];
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:[[self view] window]];
    hud.label.text = NSLocalizedString(@"Thanks!", @"Text in thank you display upon submitting feedback.");
    [hud show];
    [hud autorelease];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return [self shouldReturn:textField];
}
@end

@implementation ATContactInfoController (Private)
- (BOOL)shouldReturn:(UIView *)view {
    if (view == nameField) {
        [emailField becomeFirstResponder];
        return NO;
    } else if (view == emailField) {
        [phoneField becomeFirstResponder];
        return NO;
    } else if (view == phoneField) {
        [phoneField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)setup {
    self.title = NSLocalizedString(@"Contact Info", @"Title of contact information screen.");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", @"Label of button for submitting feedback.") style:UIBarButtonItemStyleDone target:self action:@selector(nextStep:)] autorelease];
    [self setupFeedback];
    [self setupKeyboardAccessory];
}

- (void)setupFeedback {
    if (nameField && (!nameField.text || [@"" isEqualToString:nameField.text]) && feedback.name) {
        nameField.text = feedback.name;
    }
    if (emailField && (!emailField.text || [@"" isEqualToString:emailField.text]) && feedback.email) {
        emailField.text = feedback.email;
    }
    if (phoneField && (!phoneField.text || [@"" isEqualToString:phoneField.text]) && feedback.phone) {
        phoneField.text = feedback.phone;
    }
}

- (void)setupKeyboardAccessory {
    if ([[ATConnect sharedConnection] showKeyboardAccessory]) {
        nameField.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
        emailField.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
        phoneField.inputAccessoryView = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
    }
}

- (void)teardown {
    self.feedback = nil;
    [nameField release];
    nameField = nil;
    [emailField release];
    emailField = nil;
    [phoneField release];
    phoneField = nil;
}
@end
