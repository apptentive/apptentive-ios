//
//  ApptentiveSurveyAnswerCell.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswerCell.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSurveyAnswerCell

- (BOOL)isHidden {
	return super.hidden && !self.forceUnhide;
}

@end

NS_ASSUME_NONNULL_END
