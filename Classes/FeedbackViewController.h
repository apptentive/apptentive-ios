//
//  FeedbackViewController.h
//  WowieConnect
//
//  Created by Michael Saffitz on 12/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feedback.h"

@interface FeedbackViewController : UIViewController {
	IBOutlet UITextView *feedback;
	IBOutlet UITextField *phoneNumber;
	IBOutlet UITextField *emailAddress;
}

@property (nonatomic, retain) UITextView *feedback;
@property (nonatomic, retain) UITextField *phoneNumber;
@property (nonatomic, retain) UITextField *emailAddress;

-(IBAction) sendFeedback:(id)sender;

- (BOOL)textFieldShouldReturn: (UITextField *)textField;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

@end
