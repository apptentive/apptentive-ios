//
//  ATMessageCenterInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInteraction.h"

@implementation ATMessageCenterInteraction

+ (ATMessageCenterInteraction *)messageCenterInteraction {
	ATMessageCenterInteraction *messageCenterInteraction = [[ATMessageCenterInteraction alloc] init];
	messageCenterInteraction.type = @"MessageCenter";
	
	return messageCenterInteraction;
}

@end
