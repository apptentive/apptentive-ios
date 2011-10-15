//
//  ATSimpleImageViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATCenteringImageScrollView;
@class ATFeedback;
@class ATFeedbackController;

NSString * const ATImageViewChoseImage;

@interface ATSimpleImageViewController : UIViewController <UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
    ATCenteringImageScrollView *scrollView;
	ATFeedback *feedback;
	ATFeedbackController *controller;
	BOOL shouldResign;
	UIView *containerView;
}
@property (nonatomic, retain) IBOutlet UIView *containerView;
- (id)initWithFeedback:(ATFeedback *)feedback feedbackController:(ATFeedbackController *)controller;
- (IBAction)donePressed:(id)sender;
- (IBAction)takePhoto:(id)sender;
@end
