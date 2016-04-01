//
//  ATSurveyMultilineCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyMultilineCell.h"


@implementation ApptentiveSurveyMultilineCell

- (void)awakeFromNib {
	self.placeholderLabel.isAccessibilityElement = NO;

	self.textView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
	self.textView.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.textView.layer.cornerRadius = 6.0;
	self.textView.textContainerInset = UIEdgeInsetsMake(6, 0, 6, 0);
}

@end
