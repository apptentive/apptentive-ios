//
//  ApptentiveSurveyGreetingView.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/1/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyGreetingView.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyGreetingView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *borderViewHeight;

@end


@implementation ApptentiveSurveyGreetingView

- (void)awakeFromNib {
	self.borderViewHeight.constant = 1.0 / [UIScreen mainScreen].scale;

	[super awakeFromNib];
}

- (void)setShowInfoButton:(BOOL)showInfoButton {
	_showInfoButton = showInfoButton;

	self.infoButton.hidden = !showInfoButton;

	self.infoButtonSpacer.active = showInfoButton;
}

@end

NS_ASSUME_NONNULL_END
