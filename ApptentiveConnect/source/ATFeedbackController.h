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

@interface ATFeedbackController : UIViewController {
    IBOutlet UITextField *nameField;
    IBOutlet ATDefaultTextView *feedbackView;
    IBOutlet ATPopupSelectorControl *selectorControl;
@private
    BOOL nameIsDirtied;
}
@property (nonatomic, retain) ATFeedback *feedback;
- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)nextStep:(id)sender;
@end
