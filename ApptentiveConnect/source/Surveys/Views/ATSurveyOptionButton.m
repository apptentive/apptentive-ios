//
//  ATSurveyOptionButton.m
//  Survey
//
//  Created by Frank Schmitt on 2/12/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyOptionButton.h"

@interface ATSurveyOptionButton ()

@property (assign, nonatomic) BOOL reallySetBackgroundColor;

@end

@implementation ATSurveyOptionButton

- (void)awakeFromNib	 {
	self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	[self updateColors];
	[self updateBorders];
}

- (void)setStyle:(ATSurveyOptionButtonStyle)style {
	_style = style;

	[self invalidateIntrinsicContentSize];
	[self updateBorders];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];

	[self updateColors];
}

- (void)updateBorders {
	self.layer.cornerRadius = self.style == ATSurveyOptionButtonStyleCheckbox ? 4.0 : 11.0;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	if (self.reallySetBackgroundColor) {
		[super setBackgroundColor:backgroundColor];
		self.reallySetBackgroundColor = NO;
	}
}

- (void)updateColors {
	self.reallySetBackgroundColor = YES;
	if (self.selected) {
		self.layer.borderColor = self.tintColor.CGColor;
		self.backgroundColor = self.tintColor;
		self.imageView.hidden = NO;
	} else {
		self.layer.borderColor = [UIColor colorWithWhite:0.78 alpha:1.0].CGColor;
		self.backgroundColor = [UIColor clearColor];
		self.imageView.hidden = YES;
	}
}

- (CGSize) intrinsicContentSize {
	switch (self.style) {
		case ATSurveyOptionButtonStyleCheckbox:
			return CGSizeMake(20.0, 20.0);
		case ATSurveyOptionButtonStyleRadio:
			return CGSizeMake(22.0, 22.0);
	}
}

@end
