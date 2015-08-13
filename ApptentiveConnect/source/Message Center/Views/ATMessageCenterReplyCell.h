//
//  ATMessageCenterReplyCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATNetworkImageIconView;

@interface ATMessageCenterReplyCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ATNetworkImageIconView *supportUserImageView;
@property (weak, nonatomic) IBOutlet UILabel *replyLabel;
@property (weak, nonatomic) IBOutlet UILabel *senderLabel;

@end
