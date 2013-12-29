//
//  ATTextMessageCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 12/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATBaseMessageCellV7.h"

#import "ATExpandingTextView.h"
#import "ATMessageBubbleArrowViewV7.h"
#import "ATNetworkImageView.h"
#import "ATTextMessage.h"
#import "ATTextMessageCellV7.h"
#import "PrefixedTTTAttributedLabel.h"

@interface ATTextMessageCellV7 : ATBaseMessageCellV7 <ATTTTAttributedLabelDelegate>
@property (assign, nonatomic) ATMessageBubbleArrowDirection arrowDirection;
@property (retain, nonatomic) IBOutlet UIView *textContainerView;
@property (retain, nonatomic) IBOutlet ATTTTAttributedLabel *messageLabel;
@property (retain, nonatomic) IBOutlet UIView *userIconOffsetView;
@property (retain, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (retain, nonatomic) IBOutlet ATMessageBubbleArrowViewV7 *arrowView;
@property (retain, nonatomic) IBOutlet UIImageView *composingImageView;
@property (retain, nonatomic) IBOutlet UILabel *tooLongLabel;
@property (retain, nonatomic) ATTextMessage *message;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *userIconOffsetConstraint;
@property (assign, nonatomic, getter = isTooLong) BOOL tooLong;

- (void)setup;
@end
