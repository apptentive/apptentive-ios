//
//  ApptentiveSurveyGreetingView.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/1/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveSurveyGreetingView : UIView

@property (strong, nonatomic) IBOutlet UILabel *greetingLabel;
@property (strong, nonatomic) IBOutlet UIButton *infoButton;
@property (strong, nonatomic) IBOutlet UIView *borderView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *infoButtonSpacer;

@property (assign, nonatomic) BOOL showInfoButton;

@end

NS_ASSUME_NONNULL_END
