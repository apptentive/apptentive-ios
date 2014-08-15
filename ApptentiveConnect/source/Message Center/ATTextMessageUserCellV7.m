//
//  ATTextMessageUserCellV7.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATTextMessageUserCellV7.h"
#import "ATConnect.h"

@implementation ATTextMessageUserCellV7

- (void)setup {
	self.arrowDirection = ATMessageBubbleArrowDirectionRight;
	
	UIColor *messageColor = [UIColor colorWithRed:229/255.0 green:229/255.0 blue:229/255.0 alpha:1];
	
	if ([ATConnect sharedConnection].tintColor) {
		messageColor = [ATConnect sharedConnection].tintColor;
	} else if ([self.contentView respondsToSelector:@selector(tintColor)]) {
		messageColor = self.contentView.tintColor;
	}
	
	self.textContainerView.backgroundColor = messageColor;
	
	[super setup];
}
@end
