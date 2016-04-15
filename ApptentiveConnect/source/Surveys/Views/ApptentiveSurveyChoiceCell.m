//
//  ApptentiveSurveyChoiceCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyChoiceCell.h"
#import "ApptentiveSurveyOptionButton.h"


@implementation ApptentiveSurveyChoiceCell

- (void)awakeFromNib {
	self.isAccessibilityElement = YES;

	self.textLabel.numberOfLines = 0;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	[self.button setSelected:selected];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];

	[self.button setHighlighted:highlighted];
}

@end
