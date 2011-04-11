//
//  ATSimpleImageViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATCenteringImageScrollView;
@class ATFeedback;

NSString * const ATImageViewChoseImage;

@interface ATSimpleImageViewController : UIViewController <UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
@private
    ATCenteringImageScrollView *scrollView;
	ATFeedback *feedback;
}
- (id)initWithFeedback:(ATFeedback *)feedback;
@end
