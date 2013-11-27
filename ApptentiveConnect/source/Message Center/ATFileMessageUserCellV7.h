//
//  ATFileMessageUserCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATBaseMessageCellV7.h"
#import "ATNetworkImageView.h"
#import "ATFileMessage.h"

@interface ATFileMessageUserCellV7 : ATBaseMessageCellV7
@property (retain, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (retain, nonatomic) IBOutlet UIView *imageContainerView;
@property (retain, nonatomic) ATFileMessage *message;

@end
