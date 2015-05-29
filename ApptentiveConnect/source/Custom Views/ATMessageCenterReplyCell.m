//
//  ATMessageCenterReplyCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterReplyCell.h"
#import "ATNetworkImageView.h"

@implementation ATMessageCenterReplyCell

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.supportUserImageView.layer.cornerRadius = CGRectGetWidth(self.supportUserImageView.bounds) / 2.0;
	// iOS 7 doesn't support automatic max layout width, so we have to set this explicitly.
	self.replyLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.contentView.bounds) - 8.0 - 36.0 - 30.0;
	
	[super layoutSubviews];
}

@end
