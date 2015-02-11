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

@implementation ATInteractionMessageCenterController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to load a MessageCenterController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showMessageCenterFromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.viewController = viewController;
	
	if (!self.viewController) {
		ATLogError(@"No view controller to present Message Center interface!!");
	} else {
		// Message Center interaction, Phase 1.
		// Simply call old Message Center. Not customizable.
		[[ATConnect sharedConnection] presentMessageCenterFromViewController:viewController];
	}
	
	[self release];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
