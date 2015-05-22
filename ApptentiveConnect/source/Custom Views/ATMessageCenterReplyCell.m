//
//  ATMessageCenterReplyCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterReplyCell.h"

@implementation ATMessageCenterReplyCell

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.supportUserImageView.layer.cornerRadius = CGRectGetWidth(self.supportUserImageView.bounds) / 2.0;
}

@end
