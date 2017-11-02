//
//  ApptentiveMessageCenterInputView.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/14/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterInputView.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterInputView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarLeadingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewTrailingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarBottomToTextView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelToClearButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *clearButtonToAttachButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *attachButtonToSendButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBaselines;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonCenters;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendButtonVerticalCenter;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *clearButtonLeadingToSuperview;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outerTopSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *outerBottomSpace;
@property (assign, nonatomic) CGFloat regularOuterVerticalSpace;

@property (strong, nonatomic) NSArray *landscapeConstraints;
@property (strong, nonatomic) NSArray *portraitConstraints;

@end


@implementation ApptentiveMessageCenterInputView

- (void)awakeFromNib {
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.sendBar.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.regularOuterVerticalSpace = self.outerTopSpace.constant;

	NSDictionary *views = @{ @"sendBar": self.sendBar,
		@"messageView": self.messageView };
	self.portraitConstraints = @[self.sendBarLeadingToSuperview, self.sendBarBottomToTextView, self.textViewTrailingToSuperview, self.titleLabelToClearButton, self.attachButtonToSendButton, self.clearButtonToAttachButton, self.buttonCenters, self.buttonBaselines, self.clearButtonLeadingToSuperview, self.sendButtonVerticalCenter];

	NSArray *landscapeContainerConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[messageView]-(0)-[sendBar]-(0)-|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:views];
	[self.containerView addConstraints:landscapeContainerConstraints];

	NSArray *landscapeSendBarConstraints = @[[NSLayoutConstraint constraintWithItem:self.sendBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.clearButton attribute:NSLayoutAttributeTop multiplier:1.0 constant:0], [NSLayoutConstraint constraintWithItem:self.sendBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.sendButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:4.0], [NSLayoutConstraint constraintWithItem:self.attachButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.sendBar attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
	[self.sendBar addConstraints:landscapeSendBarConstraints];

	self.landscapeConstraints = [landscapeContainerConstraints arrayByAddingObjectsFromArray:landscapeSendBarConstraints];
	[NSLayoutConstraint deactivateConstraints:self.landscapeConstraints];

	[super awakeFromNib];
}

- (void)setBorderColor:(UIColor *)borderColor {
	_borderColor = borderColor;

	self.containerView.layer.borderColor = self.borderColor.CGColor;
	self.sendBar.layer.borderColor = self.borderColor.CGColor;
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	CGFloat outerVerticalSpace = self.regularOuterVerticalSpace;

	if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
		self.titleLabel.alpha = 0;

		[NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
		[NSLayoutConstraint activateConstraints:self.landscapeConstraints];

		if (CGRectGetHeight(self.bounds) < 44.0 * 3.0) {
			outerVerticalSpace = 0.0;
		}
	} else {
		self.titleLabel.alpha = 1;

		[NSLayoutConstraint deactivateConstraints:self.landscapeConstraints];
		[NSLayoutConstraint activateConstraints:self.portraitConstraints];
	}

	self.outerTopSpace.constant = outerVerticalSpace;
	self.outerBottomSpace.constant = outerVerticalSpace;
}

@end

NS_ASSUME_NONNULL_END
