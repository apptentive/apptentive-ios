//
//  ATAutomatedMessageCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATAutomatedMessage.h"
#import "ATBaseMessageCellV7.h"

@interface ATAutomatedMessageCellV7 : ATBaseMessageCellV7
@property (retain, nonatomic) IBOutlet UILabel *messageLabel;
@property (retain, nonatomic) IBOutlet UIImageView *appIcon;
@property (retain, nonatomic) ATAutomatedMessage *message;

@end
