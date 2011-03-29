//
//  ATContactInfoController.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATFeedback;

@interface ATContactInfoController : UIViewController {
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *phoneField;
    IBOutlet UISwitch *screenshotSwitch;
}
@property (nonatomic, retain) ATFeedback *feedback;

- (IBAction)nextStep:(id)sender;
- (IBAction)imageDisclosureTapped:(id)sender;
- (IBAction)screenshotSwitchToggled:(id)sender;
@end
