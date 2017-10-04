//
//  ApptentiveMessageCenterGreetingView.h
//  Apptentive
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveNetworkImageIconView;


@interface ApptentiveMessageCenterGreetingView : UIView

@property (retain, nonatomic) IBOutlet ApptentiveNetworkImageIconView *imageView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIView *borderView;

@property (assign, nonatomic) BOOL isOnScreen;

@end

NS_ASSUME_NONNULL_END
