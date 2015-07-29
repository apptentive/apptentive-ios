//
//  ATProgressNavigationBar.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/29/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATProgressNavigationBar.h"

@implementation ATProgressNavigationBar

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self addProgressView];
	}
	return self;
}

- (void)addProgressView {
	_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
	
	self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
	[self addSubview:self.progressView];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[progress]-(0)-|" options:NSLayoutFormatAlignAllBottom metrics:nil views:@{ @"progress": self.progressView }]];
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-1]];
}

@end
