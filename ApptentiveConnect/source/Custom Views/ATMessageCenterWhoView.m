//
//  ATMessageCenterWhoView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterWhoView.h"

@interface ATMessageCenterWhoView ()

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameVerticalSpaceToEmail;

@property (strong, nonatomic) NSArray *portraitConstraints;
@property (strong, nonatomic) NSArray *landscapeConstraints;

@end

@implementation ATMessageCenterWhoView

- (void)awakeFromNib {
	self.containerView.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	
	self.portraitConstraints = @[ self.nameTrailingConstraint, self.emailLeadingConstraint, self.nameVerticalSpaceToEmail ];
	
	self.landscapeConstraints = @[ [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0],
								   [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
								   [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]
								   ];
}

- (void)updateConstraints {
	if (CGRectGetWidth(self.bounds) > 2.75 * CGRectGetHeight(self.bounds)) {
		[self.containerView removeConstraints:self.portraitConstraints];
		[self.containerView addConstraints:self.landscapeConstraints];
	} else {
		[self.containerView removeConstraints:self.landscapeConstraints];
		[self.containerView addConstraints:self.portraitConstraints];
	}
	
	[super updateConstraints];
}

@end
