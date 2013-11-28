//
//  ATTextMessageDevCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATBaseMessageCellV7.h"
#import "ATExpandingTextView.h"
#import "ATMessageBubbleArrowViewV7.h"
#import "ATNetworkImageView.h"
#import "ATTextMessage.h"
#import "TTTAttributedLabel.h"

@interface ATTextMessageDevCellV7 : ATBaseMessageCellV7 <ATTTTAttributedLabelDelegate>
@property (retain, nonatomic) IBOutlet UIView *textContainerView;
@property (retain, nonatomic) IBOutlet ATTTTAttributedLabel *messageLabel;
@property (retain, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (retain, nonatomic) IBOutlet ATMessageBubbleArrowViewV7 *arrowView;
@property (retain, nonatomic) ATTextMessage *message;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *userIconOffsetConstraint;

@end
