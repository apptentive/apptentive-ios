//
//  ApptentiveMessageCenterContextMessageCell.h
//  Apptentive
//
//  Created by Peter Kamb on 7/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveMessageCenterCellProtocols.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveMessageCenterContextMessageCell : UITableViewCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) IBOutlet UITextView *messageLabel;

@end

NS_ASSUME_NONNULL_END
