//
//  ATSurveyQuestionView.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyQuestionView.h"


@interface ATSurveyQuestionView ()

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorViewHeight;

@end


@implementation ATSurveyQuestionView

- (void)awakeFromNib {
	self.separatorViewHeight.constant = 1.0 / [UIScreen mainScreen].scale;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.textLabel.bounds);
}

@end
