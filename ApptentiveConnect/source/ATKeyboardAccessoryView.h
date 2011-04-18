//
//  ATKeyboardAccessoryView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ATKeyboardAccessoryView : UIView {
@private
    CGFloat height;
    UIView *textContainerView;
    UILabel *textLabel;
}
@end
