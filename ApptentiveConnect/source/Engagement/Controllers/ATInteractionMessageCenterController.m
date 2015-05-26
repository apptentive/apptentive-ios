//
//  ATInteractionMessageCenterController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionMessageCenterController.h"
#import "ATMessageCenterInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATMessageCenterViewController.h"

@implementation ATInteractionMessageCenterController

- (id)initWithInteraction:(ATMessageCenterInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to load a MessageCenterController with an interaction of type: %@", interaction.type);
	
#warning Also check that the interaction is of type ATMessageCenterInteraction
	
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showMessageCenterFromViewController:(UIViewController *)viewController {
	
	self.viewController = viewController;
	
	if (!self.viewController) {
		ATLogError(@"No view controller to present Message Center interface!!");
	} else {
		UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MessageCenter" bundle:[ATConnect resourceBundle]];
		UINavigationController *navigationController = [storyboard instantiateInitialViewController];
		
        ATMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;
		messageCenter.interaction = self.interaction;
		
		[viewController presentViewController:navigationController animated:YES completion:nil];
		
#warning re-add
		//messageCenter.dismissalDelegate = self;
		//self.presentedMessageCenterViewController = navigationController;

	}
	
}


@end
