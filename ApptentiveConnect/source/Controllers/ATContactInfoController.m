//
//  ATContactInfoController.m
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATContactInfoController.h"
#import <QuartzCore/QuartzCore.h>
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATFeedback.h"
#import "ATHUDView.h"
#import "ATInfoViewController.h"
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


- (IBAction)nextStep:(id)sender {
    feedback.name = nameField.text;
    feedback.email = emailField.text;
    feedback.phone = phoneField.text;
    [[ATBackend sharedBackend] sendFeedback:feedback];
    ATHUDView *hud = [[ATHUDView alloc] initWithWindow:[[self view] window]];
    hud.label.text = ATLocalizedString(@"Thanks!", @"Text in thank you display upon submitting feedback.");
    [hud show];
    [hud autorelease];
    [self dismissModalViewControllerAnimated:YES];
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
    self.title = ATLocalizedString(@"Contact Info", @"Title of contact information screen.");
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:ATLocalizedString(@"Submit", @"Label of button for submitting feedback.") style:UIBarButtonItemStyleDone target:self action:@selector(nextStep:)] autorelease];
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
        NSArray *textFields = [NSArray arrayWithObjects:nameField, emailField, phoneField, nil];
        for (UITextField *textField in textFields) {
            ATKeyboardAccessoryView *accessory = [[[ATKeyboardAccessoryView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 20.0)] autorelease];
            [accessory addTarget:self action:@selector(showInfoView:) forControlEvents:UIControlEventTouchUpInside];
            textField.inputAccessoryView = accessory;
        }
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
