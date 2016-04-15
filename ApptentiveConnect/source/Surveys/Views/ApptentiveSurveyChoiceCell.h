//
//  ApptentiveSurveyChoiceCell.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswerCell.h"

@class ApptentiveSurveyOptionButton;


@interface ApptentiveSurveyChoiceCell : ApptentiveSurveyAnswerCell

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet ApptentiveSurveyOptionButton *button;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonTopConstraint;

@end
