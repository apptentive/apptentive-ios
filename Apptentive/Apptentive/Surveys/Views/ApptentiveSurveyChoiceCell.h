//
//  ApptentiveSurveyChoiceCell.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswerCell.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyChoiceCell : ApptentiveSurveyAnswerCell

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailTextLabel;
@property (strong, nonatomic) IBOutlet UIImageView *button;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonTopConstraint;

@end

NS_ASSUME_NONNULL_END
