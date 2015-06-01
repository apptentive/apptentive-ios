//
//  ATMessageCenterReplyCell.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterReplyCell.h"
#import "ATNetworkImageIconView.h"
#import "ATBackend.h"

@implementation ATMessageCenterReplyCell

//- (void)setMaskImageToRound:(BOOL)maskImageToRound {
//	_maskImageToRound = maskImageToRound;
//	
////	[self updateImageRadius];
//}

- (void)layoutSubviews {
	[super layoutSubviews];
	
//	[self updateImageRadius];
	// iOS 7 doesn't support automatic max layout width, so we have to set this explicitly.
	self.replyLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.contentView.bounds) - 8.0 - 36.0 - 30.0;
	
	[super layoutSubviews];
}

#pragma mark - Private

//- (void)updateImageRadius {
//	if (self.maskImageToRound) {
//		self.supportUserImageView.layer.mask = nil;
//		self.supportUserImageView.layer.cornerRadius = CGRectGetWidth(self.supportUserImageView.bounds) / 2.0;
//	} else {
//		CALayer *maskLayer = [CALayer layer];
//		maskLayer.contents = (id)[ATBackend imageNamed:@"at_update_icon_mask"].CGImage;
//		maskLayer.frame = self.supportUserImageView.bounds;
//
//		self.supportUserImageView.layer.mask = maskLayer;
//		self.supportUserImageView.layer.cornerRadius = 0.0;
//	}
//	
//}

@end
