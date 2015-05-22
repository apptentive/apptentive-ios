//
//  ATMessageCenterInteraction.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 5/22/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"

@implementation ATMessageCenterInteraction

+ (ATMessageCenterInteraction *)messageCenterInteraction {
	ATMessageCenterInteraction *messageCenterInteraction = [[ATMessageCenterInteraction alloc] init];
	messageCenterInteraction.type = @"MessageCenter";
	
	return messageCenterInteraction;
}

- (NSString *)title {
	NSString *title = self.configuration[@"title"];
	
	if (!title) {
		// TODO: get title from global config
	}
	
	if (!title) {
		title = ATLocalizedString(@"Message Center", @"Default Message Center Title Text");
	}
	
	return title;
}

@end
