//
//  ATExpandingTextView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATExpandingTextView.h"

#import "ATUtilities.h"

@implementation ATExpandingTextView

- (void)layoutSubviews {
	[super layoutSubviews];
	if (!CGSizeEqualToSize(self.bounds.size, [self intrinsicContentSize])) {
		[self invalidateIntrinsicContentSize];
	}
}

- (CGSize)intrinsicContentSize {
	return [self sizeGivenWidth:self.bounds.size.width];
}

- (CGSize)sizeGivenWidth:(CGFloat)givenWidth {
	CGSize intrinsicContentSize = self.contentSize;
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7"]) {
		// Based on some of the approaches here:
		// http://stackoverflow.com/questions/18368567/uitableviewcell-with-uitextview-height-in-ios-7
		CGRect rect = CGRectMake(0, 0, givenWidth, 10000);
		CGRect insetRect = UIEdgeInsetsInsetRect(rect, self.textContainerInset);
		insetRect = UIEdgeInsetsInsetRect(insetRect, self.contentInset);
		insetRect = CGRectInset(insetRect, self.textContainer.lineFragmentPadding, 0);
		
		CGFloat width = CGRectGetWidth(insetRect);
		CGRect textSize = [self.attributedText boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
		
		CGFloat verticalPadding = rect.size.height - insetRect.size.height;
		CGFloat actualHeight = ceil(CGRectGetHeight(textSize) + verticalPadding);
		
		intrinsicContentSize.height = actualHeight;
		intrinsicContentSize.width = CGRectGetWidth(rect);
		return intrinsicContentSize;
	}
	return intrinsicContentSize;
}
@end
