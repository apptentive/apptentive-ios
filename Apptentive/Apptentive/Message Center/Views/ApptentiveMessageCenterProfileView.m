//
//  ApptentiveMessageCenterProfileView.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterProfileView.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterProfileView ()

@property (weak, nonatomic) IBOutlet UIView *buttonBar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nameVerticalSpaceToEmail;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *emailVerticalSpaceToButtonBar;

@property (strong, nonatomic) NSLayoutConstraint *nameHorizontalSpaceToEmail;

@property (strong, nonatomic) NSArray *portraitFullConstraints;
@property (strong, nonatomic) NSArray *landscapeFullConstraints;

@property (strong, nonatomic) NSArray *baseConstraints;

@end


@implementation ApptentiveMessageCenterProfileView

- (void)awakeFromNib {
	CGFloat borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.containerView.layer.borderWidth = borderWidth;
	self.buttonBar.layer.borderWidth = borderWidth;

	self.portraitFullConstraints = @[self.nameTrailingConstraint, self.emailLeadingConstraint, self.nameVerticalSpaceToEmail];

	self.nameHorizontalSpaceToEmail = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0];
	NSLayoutConstraint *nameEmailTopAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
	NSLayoutConstraint *nameEmailBottomAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];

	self.landscapeFullConstraints = @[self.nameHorizontalSpaceToEmail, nameEmailTopAlignment, nameEmailBottomAlignment];

	// Find constraints common to both modes/orientations
	NSMutableSet *baseConstraintSet = [NSMutableSet setWithArray:self.containerView.constraints];
	[baseConstraintSet minusSet:[NSSet setWithArray:self.portraitFullConstraints]];
	self.baseConstraints = [baseConstraintSet allObjects];

	[super awakeFromNib];
}

- (BOOL)becomeFirstResponder {
    return [self.nameField becomeFirstResponder];
}

- (void)setBorderColor:(UIColor *)borderColor {
	_borderColor = borderColor;

	self.containerView.layer.borderColor = self.borderColor.CGColor;
	self.buttonBar.layer.borderColor = self.borderColor.CGColor;
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	// Deactivate all, then selectively re-activate
	[NSLayoutConstraint deactivateConstraints:self.portraitFullConstraints];
	[NSLayoutConstraint deactivateConstraints:self.landscapeFullConstraints];

	if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        [NSLayoutConstraint activateConstraints:self.landscapeFullConstraints];
	} else {
        [NSLayoutConstraint activateConstraints:self.portraitFullConstraints];
	}
}

@end

NS_ASSUME_NONNULL_END
