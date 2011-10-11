//
//  ATContactInfoController.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATFeedback;

@interface ATContactInfoController_DELETE : UIViewController {
    IBOutlet UITextField *nameField;
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *phoneField;
}
@property (nonatomic, retain) ATFeedback *feedback;

- (IBAction)nextStep:(id)sender;
- (IBAction)showInfoView:(id)sender;
@end
