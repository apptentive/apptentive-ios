//
//  ATFileMessageUserCellV7.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/23/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATBaseMessageCellV7.h"
#import "ATMessageBubbleArrowViewV7.h"
#import "ATNetworkImageView.h"
#import "ATFileMessage.h"

@interface ATFileMessageUserCellV7 : ATBaseMessageCellV7
@property (strong, nonatomic) IBOutlet UIView *userIconOffsetView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *userIconOffsetConstraint;
@property (strong, nonatomic) IBOutlet ATNetworkImageView *userIconView;
@property (strong, nonatomic) IBOutlet ATMessageBubbleArrowViewV7 *arrowView;
@property (strong, nonatomic) IBOutlet UIView *imageContainerView;
@property (strong, nonatomic) IBOutlet UIView *imageShadowView;
@property (strong, nonatomic) ATFileMessage *message;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@end
