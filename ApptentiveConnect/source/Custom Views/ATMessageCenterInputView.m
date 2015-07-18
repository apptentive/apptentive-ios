//
//  ATMessageCenterInputView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 7/14/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInputView.h"

@interface ATMessageCenterInputView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarLeadingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textViewTrailingToSuperview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendBarBottomToTextView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelToClearButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *clearButtonToSendButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonBaselines;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sendButtonVerticalCenter;

@property (strong, nonatomic) NSArray *landscapeConstraints;
@property (strong, nonatomic) NSArray *portraitConstraints;

@property (strong, nonatomic) NSLayoutConstraint *landscapeSendBarConstraint;
@property (strong, nonatomic) NSArray *portraitSendBarConstraints;

@end

@implementation ATMessageCenterInputView

- (void)awakeFromNib {
	self.messageView.translatesAutoresizingMaskIntoConstraints = NO;
	self.sendBar.translatesAutoresizingMaskIntoConstraints = NO;
	
	self.containerView.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	self.sendBar.layer.borderColor = [UIColor colorWithRed:200.0/255.0 green:199.0/255.0 blue:204.0/255.0 alpha:1.0].CGColor;
	
	self.containerView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.sendBar.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	
	NSDictionary *views = @{ @"sendBar": self.sendBar, @"messageView": self.messageView };
	self.portraitConstraints = @[ self.sendBarLeadingToSuperview, self.sendBarBottomToTextView, self.textViewTrailingToSuperview ];
	
	self.landscapeConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(0)-[messageView]-(0)-[sendBar]-(0)-|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:views];
	
	self.portraitSendBarConstraints = @[ self.titleLabelToClearButton, self.clearButtonToSendButton, self.buttonBaselines ];
	
	self.landscapeSendBarConstraint = [NSLayoutConstraint constraintWithItem:self.sendButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.clearButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:8.0];
}

- (void)updateConstraints {
	if (CGRectGetWidth(self.bounds) > 2.75 * CGRectGetHeight(self.bounds)) {
		self.titleLabel.alpha = 0;
		
		[self.containerView removeConstraints:self.portraitConstraints];
		[self.containerView addConstraints:self.landscapeConstraints];
		
		[self.sendBar removeConstraints:self.portraitSendBarConstraints];
		[self.sendBar addConstraint:self.landscapeSendBarConstraint];
		
		self.sendButtonVerticalCenter.constant = -0.5 * (CGRectGetHeight(self.clearButton.bounds) + self.landscapeSendBarConstraint.constant);
	} else {
		self.titleLabel.alpha = 1;
		
		[self.containerView removeConstraints:self.landscapeConstraints];
		[self.containerView addConstraints:self.portraitConstraints];

		[self.sendBar removeConstraint:self.landscapeSendBarConstraint];
		[self.sendBar addConstraints:self.portraitSendBarConstraints];

		self.sendButtonVerticalCenter.constant = 0;
	}
	
	[super updateConstraints];
}

@end
