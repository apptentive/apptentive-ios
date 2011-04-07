//
//  ATPopupSelectorControl.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/4/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATFeedback.h"

@class ATPopupSelection;
@class ATPopupSelectorPopup;

@interface ATPopupSelectorControl : UIControl {
@private
    ATPopupSelectorPopup *popup;
}
@property (nonatomic, retain) NSArray *selections;
/*! Initialize with an array of ATPopupSelection objects. One of these should
    be selected in order for the class to work correctly. */
- (id)initWithSelections:(NSArray *)selections;
- (ATPopupSelection *)currentSelection;
@end


@interface ATPopupSelection : NSObject {
@private
}
@property (nonatomic, assign) BOOL isSelected;
- (id)initWithFeedbackType:(ATFeedbackType)type popupImage:(UIImage *)popupImage selectedImage:(UIImage *)selectedImage;
- (ATFeedbackType)feedbackType;
@end
