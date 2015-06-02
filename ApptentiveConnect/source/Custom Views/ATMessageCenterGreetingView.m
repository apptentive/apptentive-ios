//
//  ATMessageCenterGreetingView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterGreetingView.h"
#import "ATNetworkImageIconView.h"
#import <QuartzCore/QuartzCore.h>

#define LINE_BREAK_HEIGHT 150.0

@interface ATMessageCenterGreetingView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textCenterXConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textCenterYConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textHeightConstraint;

@property (weak, nonatomic) IBOutlet UIView *textContainerView;

@end

@implementation ATMessageCenterGreetingView

- (void)updateConstraints {
	if (CGRectGetHeight(self.bounds) < LINE_BREAK_HEIGHT) {
		// Landscape on phone: Center vertically, offset horizontally
		self.imageCenterYConstraint.constant = 0.0;
		self.textCenterYConstraint.constant = 0.0;
		
		self.imageCenterXConstraint.constant = self.textWidthConstraint.constant / 2.0;
		self.textCenterXConstraint.constant = -self.imageWidthConstraint.constant / 2.0;
	} else {
		// Portrait/iPad: Center horizontally, offset vertically
		self.imageCenterXConstraint.constant = 0.0;
		self.textCenterXConstraint.constant = 0.0;
		
		self.imageCenterYConstraint.constant = self.textContainerView.bounds.size.height / 2.0;
		self.textCenterYConstraint.constant = -self.imageWidthConstraint.constant / 2.0;
	}
	
	[super updateConstraints];
}

@end
