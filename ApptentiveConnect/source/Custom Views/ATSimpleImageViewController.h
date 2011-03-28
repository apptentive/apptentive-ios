//
//  ATSimpleImageViewController.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/27/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATCenteringImageScrollView;

@interface ATSimpleImageViewController : UIViewController <UIScrollViewDelegate> {
@private
    ATCenteringImageScrollView *scrollView;
}
- (id)initWithImage:(UIImage *)image;
@end
