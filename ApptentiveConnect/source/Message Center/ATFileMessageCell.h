//
//  ATFileMessageCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/20/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "ATNetworkImageView.h"
#import "ATFileMessage.h"

@interface ATFileMessageCell : UITableViewCell <ATMessageCenterCell>@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet ATNetworkImageView *userIcon;
@property (strong, nonatomic) IBOutlet UIView *imageContainer;
@property (strong, nonatomic) IBOutlet UIView *chatBubbleContainer;
@property (strong, nonatomic) IBOutlet UIImageView *messageBubbleImage;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;

- (void)configureWithFileMessage:(ATFileMessage *)message;

+ (NSString *)reuseIdentifier;
@end
