//
//  ATCustomView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 6/5/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATCustomView.h"

@implementation ATCustomView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	if (self.at_drawRectBlock) {
		self.at_drawRectBlock(self, rect);
	}
}
@end
