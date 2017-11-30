//
//  ApptentiveMessageCenterStatusView.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterStatusView.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterStatusView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageStatusSpacing;

@end


@implementation ApptentiveMessageCenterStatusView

- (void)setMode:(ATMessageCenterStatusMode)mode {
	if (_mode != mode) {
		_mode = mode;

		UIImage *statusImage;

		switch (mode) {
			case ATMessageCenterStatusModeNetworkError:
				statusImage = [[ApptentiveUtilities imageNamed:@"at_network_error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
				break;

			case ATMessageCenterStatusModeHTTPError:
				statusImage = [[ApptentiveUtilities imageNamed:@"at_error_wait"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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

		[UIView animateWithDuration:0.25
						 animations:^{
						   self.imageView.alpha = statusImage ? 1.0 : 0.0;

						   [self layoutIfNeeded];
						 }];
	}
}

@end

NS_ASSUME_NONNULL_END
