//
//  ApptentiveMessageCenterProfileView.h
//  Apptentive
//
//  Created by Frank Schmitt on 7/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATMessageCenterProfileMode) {
	ATMessageCenterProfileModeCompact = 1,
	ATMessageCenterProfileModeFull
};


@interface ApptentiveMessageCenterProfileView : UIView

@property (assign, nonatomic) ATMessageCenterProfileMode mode;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *requiredLabel;
@property (strong, nonatomic) UIColor *borderColor;

@end

NS_ASSUME_NONNULL_END
