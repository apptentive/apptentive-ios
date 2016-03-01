//
//  ATSurveyMultilineCell.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyAnswerCell.h"

@interface ATSurveyMultilineCell : ATSurveyAnswerCell

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UILabel *placeholderLabel;

@end
