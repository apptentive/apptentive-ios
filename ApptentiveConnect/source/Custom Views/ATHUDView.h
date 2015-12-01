//
//  ATHUDView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	ATHUDCheckmark
} ATHUDMarkType;


@interface ATHUDView : UIWindow
@property (readonly, strong, nonatomic) UILabel *label;
@property (assign, nonatomic) ATHUDMarkType markType;
@property (assign, nonatomic) CGSize size;
@property (assign, nonatomic) CGFloat cornerRadius;
@property (assign, nonatomic) CGFloat fadeOutDuration;

- (id)initWithWindow:(UIWindow *)window;
- (void)show;
@end
