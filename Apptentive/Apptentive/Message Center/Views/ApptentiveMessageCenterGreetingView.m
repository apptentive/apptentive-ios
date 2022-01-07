//
//  ApptentiveMessageCenterGreetingView.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterGreetingView.h"
#import "ApptentiveNetworkImageIconView.h"
#import <QuartzCore/QuartzCore.h>

#define GREETING_PORTRAIT_HEIGHT 258.0
#define GREETING_LANDSCAPE_HEIGHT 128.0

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterGreetingView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textCenterYConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBorderHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *textContainerView;

@end


@implementation ApptentiveMessageCenterGreetingView

- (void)awakeFromNib {
//	self.bottomBorderHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;

	[super awakeFromNib];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	self.translatesAutoresizingMaskIntoConstraints = NO;

	if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
		// Landscape on phone: Center vertically, offset horizontally
		self.imageCenterYConstraint.constant = 0.0;
		self.textCenterYConstraint.constant = 0.0;

		self.imageCenterXConstraint.constant = self.textWidthConstraint.constant / 2.0;
		self.textCenterXConstraint.constant = -self.imageWidthConstraint.constant / 2.0;
	} else {
		// Portrait/iPad: Center horizontally, offset vertically
		self.imageCenterXConstraint.constant = 0.0;
		self.textCenterXConstraint.constant = 0.0;

		CGSize textContainerSize = [self.textContainerView systemLayoutSizeFittingSize:CGSizeMake(self.textContainerView.bounds.size.width, 2000)];
		self.imageCenterYConstraint.constant = textContainerSize.height / 2.0 + 0.75;
		self.textCenterYConstraint.constant = -self.imageWidthConstraint.constant / 2.0 - 7.0;
	}

	self.translatesAutoresizingMaskIntoConstraints = YES;

	[self sizeToFit];
}

//- (CGSize)sizeThatFits:(CGSize)size {
//	return [self systemLayoutSizeFittingSize:CGSizeMake(size.width, 2000)];
//}

@end

NS_ASSUME_NONNULL_END
