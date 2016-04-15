//
//  ApptentiveSurveyOptionButton.h
//  Survey
//
//  Created by Frank Schmitt on 2/12/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ATSurveyOptionButtonStyle) {
	ATSurveyOptionButtonStyleCheckbox,
	ATSurveyOptionButtonStyleRadio
};


@interface ApptentiveSurveyOptionButton : UIButton

@property (assign, nonatomic) ATSurveyOptionButtonStyle style;
@property (strong, nonatomic) UIColor *borderColor;

@end
