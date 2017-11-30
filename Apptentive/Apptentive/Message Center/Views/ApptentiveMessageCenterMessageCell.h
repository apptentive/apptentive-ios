//
//  ApptentiveMessageCenterMessageCell.h
//  Apptentive
//
//  Created by Frank Schmitt on 5/21/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterCellProtocols.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterMessageCell : UITableViewCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) IBOutlet UITextView *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (assign, nonatomic) BOOL statusLabelHidden;

@end

NS_ASSUME_NONNULL_END
