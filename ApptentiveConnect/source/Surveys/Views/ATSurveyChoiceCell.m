//
//  ATSurveyChoiceCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyChoiceCell.h"
#import "ATSurveyOptionButton.h"


@implementation ATSurveyChoiceCell

- (void)awakeFromNib {
	self.isAccessibilityElement = YES;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	[self.button setSelected:selected];
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
