//
//  ATFeedbackController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATDefaultTextView;
@class ATFeedback;
@class ATKeyboardAccessoryView;
@class ATPopupSelectorControl;

@interface ATFeedbackController_DELETE : UIViewController {
    IBOutlet ATDefaultTextView *feedbackView;
    IBOutlet ATPopupSelectorControl *selectorControl;
    IBOutlet UISwitch *screenshotSwitch;
    IBOutlet UIView *screenshotContainerView;
}
@property (nonatomic, retain) ATFeedback *feedback;
@property (nonatomic, retain) NSString *customPlaceholderText;
- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)nextStep:(id)sender;
- (IBAction)imageDisclosureTapped:(id)sender;
- (IBAction)screenshotSwitchToggled:(id)sender;
- (IBAction)showInfoView:(id)sender;
@end
