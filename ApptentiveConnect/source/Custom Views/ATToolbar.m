//
//  ATToolbar.m
//  CustomWindow
//
//  Created by Andrew Wooster on 9/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATToolbar.h"
#import "ATCustomButton.h"

@implementation ATToolbar
//!! Hack to adjust frame origin of left-most custom view and to force
//!! custom views to resize on orientation changes.
//!! This is a huge hack.
- (void)layoutSubviews {
	[super layoutSubviews];
	NSArray *items = [self items];
	for (UIBarButtonItem *item in items) {
		if (item.customView != nil) {
			[item.customView sizeToFit];
		}
	}
	if ([items count] > 0) {
		UIBarButtonItem *firstItem = [items objectAtIndex:0];
		
		BOOL adjustedFirstItem = NO;
		if (firstItem.customView != nil) {
			CGRect f = firstItem.customView.frame;
			if (f.origin.x == 12.0) {
				f.origin.x = 6.0;
				firstItem.customView.frame = f;
				adjustedFirstItem = YES;
			}
		}
		
		if (adjustedFirstItem) {
			NSUInteger i = 0;
			for (UIBarButtonItem *item in items) {
				// Also don't adjust any custom buttons.
				if (i != 0 && item.customView != nil && ![item isKindOfClass:[ATCustomButton class]]) {
					CGRect customFrame = item.customView.frame;
					customFrame.origin.x += 4.0;
					item.customView.frame = customFrame;
				}
				i++;
			}
		}
	}
}

- (void)drawRect:(CGRect)rect {
	//
}
@end
