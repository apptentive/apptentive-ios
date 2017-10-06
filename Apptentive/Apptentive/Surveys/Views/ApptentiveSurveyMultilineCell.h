//
//  ApptentiveSurveyMultilineCell.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/25/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyAnswerCell.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyMultilineCell : ApptentiveSurveyAnswerCell

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UILabel *placeholderLabel;

@end

NS_ASSUME_NONNULL_END
