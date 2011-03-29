//
//  ATHUDView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ATHUDCheckmark
} ATHUDMarkType;

@interface ATHUDView : UIView {
@private
    UIView *parentView;
    UIImageView *icon;
}
@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, assign) ATHUDMarkType markType;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat cornerRadius;

- (id)initWithWindow:(UIWindow *)window;
- (void)show;
@end
