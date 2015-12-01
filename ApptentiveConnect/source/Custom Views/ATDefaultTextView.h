//
//  ATDefaultTextView.h
//  DemoApp
//
//  Created by Andrew Wooster on 3/16/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATTypes.h"


@interface ATDefaultTextView : UITextView
@property (copy, nonatomic) NSString *placeholder;
@property (copy, nonatomic) UIColor *placeholderColor;
@property (copy, readwrite, nonatomic) ATDrawRectBlock at_drawRectBlock;
- (BOOL)isDefault;
@end
