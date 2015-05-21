//
//  ATMessageCenterReplyCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATMessageCenterReplyCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *supportUserImageView;
@property (weak, nonatomic) IBOutlet UILabel *replyLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
