//
//  ATTextMessageUserCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/9/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "ATNetworkImageView.h"
#import "PrefixedTTTAttributedLabel.h"

typedef enum {
	ATTextMessageCellTypeUser,
	ATTextMessageCellTypeDeveloper,
} ATTextMessageCellType;

@interface ATTextMessageUserCell : UITableViewCell <ATMessageCenterCell, ATTTTAttributedLabelDelegate>
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UIView *chatBubbleContainer;
@property (strong, nonatomic) IBOutlet ATNetworkImageView *userIcon;
@property (strong, nonatomic) IBOutlet UIImageView *messageBubbleImage;
@property (strong, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) IBOutlet ATTTTAttributedLabel *messageText;
@property (strong, nonatomic) IBOutlet UIImageView *composingBubble;
@property (strong, nonatomic) IBOutlet UILabel *tooLongLabel;
@property (nonatomic, assign, getter = isComposing) BOOL composing;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;
@property (nonatomic, assign, getter = isTooLong) BOOL tooLong;
@property (nonatomic, assign) ATTextMessageCellType cellType;
@end
