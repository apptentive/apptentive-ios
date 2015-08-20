//
//  ATMessageCenterGreetingView.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATNetworkImageIconView;

@interface ATMessageCenterGreetingView : UIView

@property (retain, nonatomic) IBOutlet ATNetworkImageIconView *imageView;
@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
<<<<<<< HEAD
@property (assign, nonatomic) BOOL isOnScreen;
=======
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
>>>>>>> 305478a265adce42e0f0a1af08d0b45dbfe82161

@end
