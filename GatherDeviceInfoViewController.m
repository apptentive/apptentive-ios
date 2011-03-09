//
//  GatherDeviceInfoViewController.m
//  WowieConnect
//
//  Created by Michael Saffitz on 1/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GatherDeviceInfoViewController.h"
#import "WowieConnect.h"


@implementation GatherDeviceInfoViewController

// TODO -- they keyboard obscures the textfields
// http://joshhighland.com/blog/2010/04/20/iphone-keyboard-covers-text-field/

@synthesize firstName;
@synthesize lastName;
@synthesize emailAddress;
@synthesize cancelButton;
@synthesize continueButton;

-(IBAction) checkContinueButtonState:(id)sender
{
    self.continueButton.enabled = (([firstName.text length] != 0) &&
                                    ([lastName.text length] != 0) &&
                                ([emailAddress.text length] != 0) );
}

-(IBAction) continueToFeedback:(id)sender
{
    [[WowieConnect sharedInstance] recordDeviceWithFirstName:firstName.text
                                                 andLastName:lastName.text
                                                    andEmail:emailAddress.text];

    [[WowieConnect sharedInstance] presentWowieConnectModalViewControllerForParent:[self parentViewController]];
}

-(IBAction) cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkContinueButtonState:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

//
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
//{
//    return NO;
//}

@end
