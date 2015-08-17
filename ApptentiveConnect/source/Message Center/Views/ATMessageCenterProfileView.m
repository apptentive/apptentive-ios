//
//  ATMessageCenterProfileView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterProfileView.h"

@interface ATMessageCenterProfileView ()

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emailLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *nameVerticalSpaceToEmail;

@property (strong, nonatomic) NSLayoutConstraint *nameHorizontalSpaceToEmail;

@property (strong, nonatomic) NSMutableArray *portraitConstraints;
@property (strong, nonatomic) NSMutableArray *landscapeConstraints;

@end

@implementation ATMessageCenterProfileView

- (void)awakeFromNib {
	self.containerView.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	
	self.portraitConstraints = [@[self.nameTrailingConstraint, self.emailLeadingConstraint, self.nameVerticalSpaceToEmail] mutableCopy];
	
	self.nameHorizontalSpaceToEmail = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeLeading multiplier:1.0 constant:-8.0];
	NSLayoutConstraint *nameEmailTopAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
	NSLayoutConstraint *nameEmailBottomAlignment = [NSLayoutConstraint constraintWithItem:self.nameField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.emailField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
	
	self.landscapeConstraints = [@[self.nameHorizontalSpaceToEmail, nameEmailTopAlignment, nameEmailBottomAlignment] mutableCopy];
}

- (BOOL)isSizeLandscape:(CGSize)size {
	return size.width > 2.75 * size.height;
}

- (void)updateConstraints {
	if ([self isSizeLandscape:self.bounds.size]) {
		[self.containerView removeConstraints:self.portraitConstraints];
		[self.containerView addConstraints:self.landscapeConstraints];
	} else {
		[self.containerView removeConstraints:self.landscapeConstraints];
		[self.containerView addConstraints:self.portraitConstraints];
	}
	
	[super updateConstraints];
}

- (void)setMode:(ATMessageCenterProfileMode)mode {
	if (_mode != mode) {
		_mode = mode;
		
		CGFloat nameFieldAlpha;
		
		if (mode == ATMessageCenterProfileModeCompact) {
			nameFieldAlpha = 0;
			
			[self.portraitConstraints removeObject:self.nameVerticalSpaceToEmail];
			
			[self.landscapeConstraints removeObject:self.nameHorizontalSpaceToEmail];
			[self.landscapeConstraints addObject:self.emailLeadingConstraint];
			
			if (![self isSizeLandscape:self.bounds.size]) {
				[self.containerView removeConstraint:self.nameVerticalSpaceToEmail];
			} else {
				[self.containerView removeConstraint:self.nameHorizontalSpaceToEmail];
				[self.containerView addConstraint:self.emailLeadingConstraint];
			}
		} else {
			self.nameField.hidden = NO;
			nameFieldAlpha = 1;
			
			[self.portraitConstraints addObject:self.nameVerticalSpaceToEmail];
			
			[self.landscapeConstraints addObject:self.nameHorizontalSpaceToEmail];
			[self.landscapeConstraints removeObject:self.emailLeadingConstraint];
			
			if (![self isSizeLandscape:self.bounds.size]) {
				[self.containerView addConstraint:self.nameVerticalSpaceToEmail];
			} else {
				[self.containerView addConstraint:self.nameHorizontalSpaceToEmail];
				[self.containerView removeConstraint:self.emailLeadingConstraint];
			}
		}
		
		[UIView animateWithDuration:0.25 animations:^{
			self.nameField.alpha = nameFieldAlpha;
			
			[self layoutIfNeeded];
		} completion:^(BOOL finished) {
			if (nameFieldAlpha == 0) {
				self.nameField.hidden = YES;
			}
		}];
	}
}

@end