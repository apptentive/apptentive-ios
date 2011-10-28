//
//  ATCustomButton.h
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	ATCustomButtonStyleCancel,
	ATCustomButtonStyleDone
} ATCustomButtonStyle;

@interface ATTrackingButton : UIButton {
@private
    UIEdgeInsets padding;
}
@property (nonatomic, assign) UIEdgeInsets padding;
@end

@interface ATCustomButton : UIBarButtonItem
- (id)initWithButtonStyle:(ATCustomButtonStyle)style;
- (void)setAction:(SEL)action forTarget:(id)target;
@end
