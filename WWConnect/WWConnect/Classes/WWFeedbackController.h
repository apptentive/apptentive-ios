//
//  WWFeedbackController.h
//  wowie-sdk
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Uncorked Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WWFeedbackController : UINavigationController {
    IBOutlet UITextField *nameField;
    IBOutlet UITextView *feedbackView;
}
- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)nextStep:(id)sender;
@end
