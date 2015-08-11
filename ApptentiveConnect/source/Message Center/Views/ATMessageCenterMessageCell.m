//
//  ATMessageCenterMessageCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterMessageCell.h"

@interface ATMessageCenterMessageCell ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *messageStatusSpacingConstraint;

@end

@implementation ATMessageCenterMessageCell

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// iOS 7 doesn't support automatic max layout width, so we have to set this explicitly.
	self.messageLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.contentView.bounds) - 30.0;
	
	[super layoutSubviews];
}

@end
