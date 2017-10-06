//
//  ApptentiveMessageCenterMessageCell.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterMessageCell.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterMessageCell ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *statusLabelBottomConstraint;

@end


@implementation ApptentiveMessageCenterMessageCell

- (void)awakeFromNib {
	self.messageLabel.textContainerInset = UIEdgeInsetsZero;
	self.messageLabel.textContainer.lineFragmentPadding = 0;

	[super awakeFromNib];
}


- (void)setStatusLabelHidden:(BOOL)statusLabelHidden {
	_statusLabelHidden = statusLabelHidden;

	self.statusLabel.hidden = statusLabelHidden;

	self.statusLabelBottomConstraint.active = !statusLabelHidden;
}

@end

NS_ASSUME_NONNULL_END
