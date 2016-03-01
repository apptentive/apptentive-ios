//
//  ATSurveyQuestionBackgroundView.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyQuestionBackgroundView.h"
#import "ATSurveyLayoutAttributes.h"

@implementation ATSurveyQuestionBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		self.layer.cornerRadius = 2.0;
		self.backgroundColor = [UIColor whiteColor];
		self.valid = YES;
	}

	return self;
}

- (void)setValid:(BOOL)valid {
	_valid = valid;

	self.layer.borderColor = (valid ? [UIColor colorWithWhite:0.8 alpha:1.0] : [UIColor colorWithRed:0.85 green:0.22 blue:0.29 alpha:1.0]).CGColor;
	self.layer.borderWidth = valid ? 1.0 / [UIScreen mainScreen].scale : 1.0;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
	[super applyLayoutAttributes:layoutAttributes];

	if ([layoutAttributes isKindOfClass:[ATSurveyLayoutAttributes class]]) {
		self.valid = ((ATSurveyLayoutAttributes *)layoutAttributes).valid;
	}
}

@end
