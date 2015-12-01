//
//  ATMessageCenterStatusView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterStatusView.h"
#import "ATBackend.h"


@interface ATMessageCenterStatusView ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *imageStatusSpacing;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end


@implementation ATMessageCenterStatusView

- (void)setMode:(ATMessageCenterStatusMode)mode {
	if (_mode != mode) {
		_mode = mode;

		UIImage *statusImage;

		switch (mode) {
			case ATMessageCenterStatusModeNetworkError:
				statusImage = [ATBackend imageNamed:@"at_network_error"];
				break;

			case ATMessageCenterStatusModeHTTPError:
				statusImage = [ATBackend imageNamed:@"at_error_wait"];
				break;

			default:
				statusImage = nil;
				break;
		}

		self.imageView.image = statusImage;

		if ([self.constraints containsObject:self.imageStatusSpacing] && statusImage == nil) {
			[self removeConstraint:self.imageStatusSpacing];
		} else if (statusImage != nil) {
			[self addConstraint:self.imageStatusSpacing];
		}

		[UIView animateWithDuration:0.25 animations:^{
			self.imageView.alpha = statusImage ? 1.0 : 0.0;
			
			[self layoutIfNeeded];
		}];
	}
}

@end
