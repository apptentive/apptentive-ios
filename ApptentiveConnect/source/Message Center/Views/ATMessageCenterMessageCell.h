//
//  ATMessageCenterMessageCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATMessageCenterCellProtocols.h"

@interface ATMessageCenterMessageCell : UITableViewCell <ATMessageCenterCell>

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (assign, nonatomic) BOOL statusLabelHidden;

@end
