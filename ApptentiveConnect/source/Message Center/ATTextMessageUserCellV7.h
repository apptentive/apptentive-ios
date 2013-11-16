//
//  ATTextMessageUserCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/14/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATExpandingTextView.h"
#import "ATNetworkImageView.h"
#import "ATTextMessage.h"
#import "TTTAttributedLabel.h"

@interface ATTextMessageUserCellV7 : UICollectionViewCell <ATTTTAttributedLabelDelegate>
@property (retain, nonatomic) IBOutlet UIView *textContainerView;
@property (retain, nonatomic) IBOutlet ATTTTAttributedLabel *messageLabel;
@property (retain, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (retain, nonatomic) ATTextMessage *message;

@end
