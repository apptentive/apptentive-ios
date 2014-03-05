//
//  ATInteractionMessageCenterController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionMessageCenterController.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATAppRatingMetrics.h"

@implementation ATInteractionMessageCenterController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to load a MessageCenterController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = interaction;
	}
	return self;
}

- (void)showMessageCenterFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;
	
	if (!self.viewController) {
		ATLogError(@"No view controller to present Message Center interface!!");
	} else {
		//TODO: present Message Center
	}
}

@end
