//
//  ATAutomatedMessageCell.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/19/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATMessageCenterCell.h"
#import "PrefixedTTTAttributedLabel.h"

@interface ATAutomatedMessageCell : UITableViewCell <ATMessageCenterCell>
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet ATTTTAttributedLabel *titleText;
@property (strong, nonatomic) IBOutlet UIView *grayLineView;
@property (strong, nonatomic) IBOutlet ATTTTAttributedLabel *messageText;
@property (nonatomic, assign, getter = shouldShowDateLabel) BOOL showDateLabel;

+ (NSString *)reuseIdentifier;
@end
