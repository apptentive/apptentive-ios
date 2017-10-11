//
//  ApptentiveSurveyQuestionBackgroundView.h
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyQuestionBackgroundView : UICollectionReusableView

@property (assign, nonatomic, getter=isValid) BOOL valid;
@property (strong, nonatomic) UIColor *validColor;
@property (strong, nonatomic) UIColor *invalidColor;

@end

NS_ASSUME_NONNULL_END
