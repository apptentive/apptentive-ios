//
//  ATSurveyChoiceCell.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyAnswerCell.h"

@class ATSurveyOptionButton;


@interface ATSurveyChoiceCell : ATSurveyAnswerCell

@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet ATSurveyOptionButton *button;

@end
