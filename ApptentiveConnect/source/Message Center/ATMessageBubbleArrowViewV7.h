//
//  ATMessageBubbleArrowViewV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/27/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ATMessageBubbleArrowDirection) {
	ATMessageBubbleArrowDirectionLeft,
	ATMessageBubbleArrowDirectionRight
};

@interface ATMessageBubbleArrowViewV7 : UIView
@property (nonatomic, assign) ATMessageBubbleArrowDirection direction;
@property (nonatomic, copy) UIColor *color;
@end
