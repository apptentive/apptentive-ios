//
//  UIViewController+ATSwizzle.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 11/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (ATSwizzle)
- (void)at_swizzleDidRotateFromInterfaceOrientation;
@end

void ATSwizzle_UIViewController_Bootstrap();
