//
//  ATSurveySubmitButton.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 2/11/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveySubmitButton.h"


@implementation ATSurveySubmitButton

- (void)awakeFromNib {
	self.titleEdgeInsets = UIEdgeInsetsMake(4.0, 26.0, 4.0, 26.0);

	self.layer.borderColor = self.tintColor.CGColor;
	self.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
	self.layer.cornerRadius = 6.0;
}

- (CGSize)intrinsicContentSize {
	CGSize s = [super intrinsicContentSize];

	return CGSizeMake(s.width + self.titleEdgeInsets.left + self.titleEdgeInsets.right, s.height + self.titleEdgeInsets.top + self.titleEdgeInsets.bottom);
}
@end
