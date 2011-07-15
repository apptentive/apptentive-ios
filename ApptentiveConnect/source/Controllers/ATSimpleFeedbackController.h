//
//  ATSimpleFeedbackController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/13/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATDefaultTextView;
@class ATFeedback;
@class ATKeyboardAccessoryView;

@interface ATSimpleFeedbackController : UIViewController <UITextFieldDelegate> {
    IBOutlet ATDefaultTextView *feedbackView;
    IBOutlet UITextField *emailField;
    IBOutlet UIView *emailContainerView;
}

@property (nonatomic, retain) ATFeedback *feedback;
@property (nonatomic, retain) NSString *customPlaceholderText;
- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)nextStep:(id)sender;
- (IBAction)showInfoView:(id)sender;
@end
