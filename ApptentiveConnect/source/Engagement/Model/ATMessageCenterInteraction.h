//
//  ATMessageCenterInteraction.h
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteraction.h"

@interface ATMessageCenterInteraction : ATInteraction

+ (ATMessageCenterInteraction *)messageCenterInteraction;

@property (nonatomic, readonly) NSString *title;

@end
