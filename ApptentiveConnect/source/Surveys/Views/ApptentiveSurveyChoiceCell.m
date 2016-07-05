//
//  ApptentiveSurveyChoiceCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyChoiceCell.h"


@implementation ApptentiveSurveyChoiceCell

- (void)awakeFromNib {
	self.isAccessibilityElement = YES;

	self.textLabel.numberOfLines = 0;

	[super awakeFromNib];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	[self.button setHighlighted:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];

	[self.button setHighlighted:highlighted];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	self.textLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.textLabel.bounds);
}

@end
