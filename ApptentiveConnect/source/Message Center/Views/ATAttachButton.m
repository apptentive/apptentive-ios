//
//  ATAttachButton.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/9/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ATAttachButton.h"

@implementation ATAttachButton

- (void)awakeFromNib {
	self.titleLabel.backgroundColor = self.tintColor;
	self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleEdgeInsets = UIEdgeInsetsMake(-8.0, 0.0, 0.0, 0.0);
	self.titleLabel.layer.masksToBounds = YES;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat height = CGRectGetHeight(self.titleLabel.bounds);
	CGFloat width = CGRectGetWidth(self.titleLabel.bounds);

	self.titleLabel.bounds = CGRectMake(0, 0, fmax(width, height), height);
	self.titleLabel.layer.cornerRadius = height / 2.0;
}

- (void)setBadgeValue:(NSInteger)badgeValue {
	_badgeValue = badgeValue;

	if (badgeValue > 0) {
		[self setTitle:[NSString stringWithFormat:@"%ld", (long)badgeValue] forState:UIControlStateNormal];
	} else {
		[self setTitle:nil forState:UIControlStateNormal];
	}
}


@end
