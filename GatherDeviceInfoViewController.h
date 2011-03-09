//
//  GatherDeviceInfoViewController.h
//  WowieConnect
//
//  Created by Michael Saffitz on 1/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface GatherDeviceInfoViewController : UIViewController {
    IBOutlet UITextField *firstName;
    IBOutlet UITextField *lastName;
    IBOutlet UITextField *emailAddress;
    IBOutlet UIButton *continueButton;
    IBOutlet UIButton *cancelButton;
}

@property (nonatomic, retain) UITextField *firstName;
@property (nonatomic, retain) UITextField *lastName;
@property (nonatomic, retain) UITextField *emailAddress;
@property (nonatomic, retain) UIButton *continueButton;
@property (nonatomic, retain) UIButton *cancelButton;

-(IBAction) checkContinueButtonState:(id)sender;
-(IBAction) continueToFeedback:(id)sender;
-(IBAction) cancel:(id)sender;

- (BOOL)textFieldShouldReturn:(UITextField *)textField;

@end
