//
//  ApptentiveInteractionMessageCenterController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionMessageCenterController.h"
#import "ApptentiveMessageCenterInteraction.h"
#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveInteraction.h"


@interface ApptentiveInteractionMessageCenterController ()

@property (strong, nonatomic) UIViewController *viewController;

@end


@implementation ApptentiveInteractionMessageCenterController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"MessageCenter"];
}

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction {
	ApptentiveMessageCenterInteraction *messageCenterInteraction = [ApptentiveMessageCenterInteraction messageCenterInteractionFromInteraction:interaction];

	return [super initWithInteraction:messageCenterInteraction];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;

	if (!self.viewController) {
		ApptentiveLogError(@"No view controller to present Message Center interface!!");
	} else {
		UINavigationController *navigationController = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"MessageCenterNavigation"];

		ApptentiveMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;
		messageCenter.interaction = (ApptentiveMessageCenterInteraction *)self.interaction;

		[viewController presentViewController:navigationController animated:YES completion:nil];
	}
}

@end
