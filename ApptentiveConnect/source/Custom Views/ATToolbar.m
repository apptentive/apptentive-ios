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
@synthesize at_drawRectBlock;

//!! Hack to adjust frame origin of left-most custom view and to force
//!! custom views to resize on orientation changes.
//!! Still has problems if the text is too big to fit and is rotated to portrait twice.
//!! This is a huge hack.
- (void)layoutSubviews {
	[super layoutSubviews];
	
	NSArray *items = [self items];
	CGFloat widthAvailable = self.bounds.size.width;
	
	BOOL viewHasTwoButtons = NO;
	NSUInteger buttonCount = 0;
	for (UIBarButtonItem *item in items) {
		if ([item isKindOfClass:[ATCustomButton class]]) {
			buttonCount++;
		}
	}
	if (buttonCount == 2) {
		viewHasTwoButtons = YES;
	}
	
	NSUInteger customButtonIndex = 0;
	for (UIBarButtonItem *item in items) {
		if (item.customView != nil && item.customView.superview != nil) {
			[item.customView sizeToFit];
			if (viewHasTwoButtons && [item isKindOfClass:[ATCustomButton class]]) {
				CGRect frameInView = [item.customView.superview convertRect:item.customView.frame toView:self];
				if (customButtonIndex == 0) {
					widthAvailable -= CGRectGetMaxX(frameInView);
				} else if (customButtonIndex == 1) {
					CGFloat buttonOriginWidth = (self.bounds.size.width - frameInView.origin.x);
					widthAvailable -= buttonOriginWidth;
				}
				customButtonIndex++;
			}
		}
	}
	
	if ([items count] > 0) {
		UIBarButtonItem *firstItem = [items objectAtIndex:0];
		UIBarButtonItem *lastItem = [items lastObject];
		
		BOOL adjustedFirstItem = NO;
		CGFloat firstItemAdjustment = 0;
		
		if (firstItem.customView != nil) {
			CGRect f = firstItem.customView.frame;
			if (f.origin.x == 12.0) {
				firstItemAdjustment = -6;
				f.origin.x += firstItemAdjustment;
				firstItem.customView.frame = f;
				adjustedFirstItem = YES;
			} else if (f.origin.x == 16) {
				// iOS 7 Devices
				firstItemAdjustment = -10;
				f.origin.x += firstItemAdjustment;
				firstItem.customView.frame = f;
				adjustedFirstItem = YES;
			}
			widthAvailable -= firstItemAdjustment;
		}
		
		if (lastItem && lastItem.customView != nil) {
			CGFloat lastItemAdjustment = 0;
			CGRect f = lastItem.customView.frame;
			CGFloat endPadding = self.bounds.size.width - f.origin.x - f.size.width;
			if (endPadding == 16) {
				lastItemAdjustment = 10;
				f.origin.x += lastItemAdjustment;
				widthAvailable += lastItemAdjustment;
				lastItem.customView.frame = f;
			}
		}
		
		if (adjustedFirstItem) {
			NSUInteger i = 0;
			for (UIBarButtonItem *item in items) {
				// Also don't adjust any custom buttons.
				if (i != 0 && item.customView != nil && ![item isKindOfClass:[ATCustomButton class]]) {
					CGRect customFrame = item.customView.frame;
					customFrame.size.width = MIN(widthAvailable, customFrame.size.width);
					CGFloat widthDiff = customFrame.origin.x - CGRectGetMaxX(firstItem.customView.frame);
					if (widthDiff < 0) {
						// Only adjust the x origin if the label is going to overlap the first button.
						customFrame.origin.x -= (widthDiff + floor(firstItemAdjustment*0.5));
					}
					item.customView.frame = customFrame;
				}
				i++;
			}
		}
		
		// Explicitly center the label.
		NSUInteger i = 0;
		for (UIBarButtonItem *item in items) {
			// Also don't adjust any custom buttons.
			if (i != 0 && item.customView != nil && ![item isKindOfClass:[ATCustomButton class]]) {
				CGRect customFrame = item.customView.frame;
				CGFloat gap = widthAvailable - customFrame.size.width;
				if (gap > 0) {
					// Explicitly center the label.
					CGFloat leftPadding = ceil(gap * 0.5);
					customFrame.origin.x = CGRectGetMaxX(firstItem.customView.frame) + leftPadding;
					item.customView.frame = customFrame;
				}
			}
			i++;
		}
	}
}

- (void)drawRect:(CGRect)rect {
	if (at_drawRectBlock) {
		at_drawRectBlock(self, rect);
	}
}

- (void)dealloc {
	[at_drawRectBlock release], at_drawRectBlock = nil;
	[super dealloc];
}
@end


void ATToolbar_Bootstrap() {
	NSLog(@"Loading ATToolbar_Bootstrap");
}
