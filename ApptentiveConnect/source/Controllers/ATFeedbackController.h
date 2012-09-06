//
//  ATFeedbackController.h
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATDefaultTextView;
@class ATFeedback;
@class ATToolbar;

typedef enum {
	ATFeedbackAllowPhotoAttachment = 1,
	ATFeedbackAllowTakePhotoAttachment = 2,
} ATFeedbackAttachmentOptions;

@interface ATFeedbackController : UIViewController <UITextFieldDelegate> {
	UIViewController *presentingViewController;
	
@private
	UIStatusBarStyle startingStatusBarStyle;
	UIImageView *paperclipView;
	UIImageView *paperclipBackgroundView;
	UIImageView *photoFrameView;
	UIControl *photoControl;
	UIImage *currentImage;
	BOOL showEmailAddressField;
	BOOL deleteCurrentFeedbackOnCancel;
	
	UIWindow *originalPresentingWindow;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet ATToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *redLineView;
@property (nonatomic, retain) IBOutlet UIView *grayLineView;
@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UIView *feedbackContainerView;
@property (nonatomic, retain) IBOutlet ATDefaultTextView *feedbackView;
@property (nonatomic, retain) IBOutlet UIControl *logoControl;
@property (nonatomic, retain) IBOutlet UIImageView *logoImageView;
@property (nonatomic, retain) IBOutlet UILabel *taglineLabel;


@property (nonatomic, retain) ATFeedback *feedback;
@property (nonatomic, retain) NSString *customPlaceholderText;
@property (nonatomic, assign) ATFeedbackAttachmentOptions attachmentOptions;
@property (nonatomic, assign) BOOL showEmailAddressField;
@property (nonatomic, assign) BOOL deleteCurrentFeedbackOnCancel;

- (id)init;
- (IBAction)cancelFeedback:(id)sender;
- (IBAction)donePressed:(id)sender;
- (IBAction)photoPressed:(id)sender;
- (IBAction)showInfoView:(id)sender;

- (void)presentFromViewController:(UIViewController *)presentingViewController animated:(BOOL)animated;
- (void)dismiss:(BOOL)animated;
- (void)unhide:(BOOL)animated;
@end
