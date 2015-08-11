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

@end
