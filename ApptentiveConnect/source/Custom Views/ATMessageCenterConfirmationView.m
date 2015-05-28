//
//  ATMessageCenterConfirmationView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterConfirmationView.h"

@interface ATMessageCenterConfirmationView ()

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *confirmationStatusSpacing;

@end

@implementation ATMessageCenterConfirmationView

- (void)setConfirmationHidden:(BOOL)confirmationHidden {
	if (confirmationHidden) {
		[self removeConstraint:self.confirmationStatusSpacing];
	} else {
		[self addConstraint:self.confirmationStatusSpacing];
	}
	
	[UIView animateWithDuration:0.3 animations:^{
		self.confirmationLabel.alpha = confirmationHidden ? 0.0 : 1.0;

		[self layoutIfNeeded];
	}];
}

@end
