//
//  ApptentiveCompoundMessageCell.m
//  Apptentive
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCompoundMessageCell.h"


@interface ApptentiveCompoundMessageCell ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *messageLabelCollectionViewSpacing;

@end


@implementation ApptentiveCompoundMessageCell

- (void)setMessageLabelHidden:(BOOL)messageLabelHidden {
	_messageLabelHidden = messageLabelHidden;

	if (messageLabelHidden) {
		[self.contentView removeConstraint:self.messageLabelCollectionViewSpacing];
	} else {
		[self.contentView addConstraint:self.messageLabelCollectionViewSpacing];
	}
}

@end
