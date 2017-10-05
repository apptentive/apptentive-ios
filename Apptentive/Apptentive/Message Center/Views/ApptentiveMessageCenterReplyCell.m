//
//  ApptentiveMessageCenterReplyCell.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterReplyCell.h"
#import "ApptentiveNetworkImageIconView.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveMessageCenterReplyCell

- (void)awakeFromNib {
	self.messageLabel.textContainerInset = UIEdgeInsetsMake(-1, 0, 0, 0);
	self.messageLabel.textContainer.lineFragmentPadding = 0;

	[super awakeFromNib];
}

@end

NS_ASSUME_NONNULL_END
