//
//  ATMessageCenterReplyCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATMessageCenterCellProtocols.h"

@class ATNetworkImageIconView;


@interface ATMessageCenterReplyCell : UITableViewCell <ATMessageCenterCell>

@property (weak, nonatomic) IBOutlet ATNetworkImageIconView *supportUserImageView;
@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;

@end
