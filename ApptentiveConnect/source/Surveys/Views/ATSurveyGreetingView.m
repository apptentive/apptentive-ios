//
//  ATSurveyGreetingView.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/1/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyGreetingView.h"


@interface ATSurveyGreetingView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *borderViewHeight;

@end


@implementation ATSurveyGreetingView

- (void)awakeFromNib {
	self.borderViewHeight.constant = 1.0 / [UIScreen mainScreen].scale;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.greetingLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.greetingLabel.bounds);

	[super layoutSubviews];
}

@end
