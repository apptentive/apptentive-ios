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
    IBOutlet UIImageView *screenshotView;
    IBOutlet UISwitch *screenshotSwitch;
    IBOutlet UIControl *imageControl;
@private
    CGRect screenshotFrame;
    BOOL previewingImage;
}
@property (nonatomic, retain) ATFeedback *feedback;
@property (nonatomic, retain) IBOutlet UIImageView *screenshotView;

- (IBAction)nextStep:(id)sender;
- (IBAction)screenshotSwitchToggled:(id)sender;
- (IBAction)imageDisclosureTapped:(id)sender;
- (IBAction)imageControlTapped:(id)sender; //!!-
@end
