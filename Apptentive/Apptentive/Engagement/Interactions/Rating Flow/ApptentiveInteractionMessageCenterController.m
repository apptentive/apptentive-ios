//
//  ApptentiveInteractionMessageCenterController.m
//  Apptentive
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionMessageCenterController.h"
#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveUtilities.h"


@implementation ApptentiveInteractionMessageCenterController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"MessageCenter"];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	UINavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"MessageCenterNavigation"];

	ApptentiveMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;
	ApptentiveMessageCenterViewModel *viewModel = [[ApptentiveMessageCenterViewModel alloc] initWithDelegate:messageCenter];
	viewModel.interaction = self.interaction;

	messageCenter.viewModel = viewModel;

	[viewController presentViewController:navigationController animated:YES completion:nil];
}

@end
