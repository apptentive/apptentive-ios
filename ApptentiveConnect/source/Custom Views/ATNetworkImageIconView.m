//
//  ATNetworkImageIconView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 6/1/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATNetworkImageIconView.h"
#import "ATBackend.h"

@implementation ATNetworkImageIconView

- (void)setMaskType:(ATImageViewMaskType)maskType {
	_maskType = maskType;
	
	[self updateImageMask];
}

- (void)updateImageMask {
	switch (self.maskType) {
		case ATImageViewMaskTypeNone:
			self.layer.cornerRadius = 0.0;
			self.layer.mask = nil;
			break;
			
		case ATImageViewMaskTypeRound:
			self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2.0;
			self.layer.mask = nil;
			break;
			
		case ATImageViewMaskTypeAppIcon: {
			CALayer *maskLayer = [CALayer layer];
			maskLayer.contents = (id)[ATBackend imageNamed:@"at_update_icon_mask"].CGImage;
			maskLayer.frame = self.bounds;
			
			self.layer.cornerRadius = 0.0;
			self.layer.mask = maskLayer;
			break;
		}
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	[self updateImageMask];
}

@end
