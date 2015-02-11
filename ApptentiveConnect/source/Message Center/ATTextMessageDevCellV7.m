//
//  ATTextMessageDevCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessageDevCellV7.h"

@implementation ATTextMessageDevCellV7
- (void)setup {
	self.arrowDirection = ATMessageBubbleArrowDirectionLeft;
	self.textContainerView.backgroundColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1];
	[super setup];
}
@end
