//
//  WWFeedbackController.h
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATDefaultTextView;

@interface WWFeedbackController : UIViewController {
    IBOutlet UITextField *nameField;
    IBOutlet ATDefaultTextView *feedbackView;
    IBOutlet UIBarButtonItem *nextButton;
}
- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)nextStep:(id)sender;
@end
