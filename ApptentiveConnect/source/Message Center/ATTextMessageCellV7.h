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
@property (strong, nonatomic) IBOutlet UIView *textContainerView;
@property (strong, nonatomic) IBOutlet ATTTTAttributedLabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIView *userIconOffsetView;
@property (strong, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (strong, nonatomic) IBOutlet ATMessageBubbleArrowViewV7 *arrowView;
@property (strong, nonatomic) IBOutlet UIImageView *composingImageView;
@property (strong, nonatomic) IBOutlet UILabel *tooLongLabel;
@property (strong, nonatomic) ATTextMessage *message;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *userIconOffsetConstraint;
@property (assign, nonatomic, getter = isTooLong) BOOL tooLong;

- (void)setup;
@end
