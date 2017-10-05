//
//  ApptentiveMessageCenterContextMessageCell.m
//  Apptentive
//
//  Created by Peter Kamb on 7/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterContextMessageCell.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveMessageCenterContextMessageCell

- (void)awakeFromNib {
	self.messageLabel.textContainerInset = UIEdgeInsetsZero;
	self.messageLabel.textContainer.lineFragmentPadding = 0;

	[super awakeFromNib];
}

@end

NS_ASSUME_NONNULL_END
