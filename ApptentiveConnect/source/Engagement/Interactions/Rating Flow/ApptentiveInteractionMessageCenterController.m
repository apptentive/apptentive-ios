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


@interface ApptentiveInteractionMessageCenterController ()

@property (readonly, strong, nonatomic) ApptentiveMessageCenterInteraction *interaction;
@property (strong, nonatomic) UIViewController *viewController;

@end


@implementation ApptentiveInteractionMessageCenterController

- (id)initWithInteraction:(ApptentiveInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to load a MessageCenterController with an interaction of type: %@", interaction.type);

	self = [super init];
	if (self != nil) {
		ApptentiveMessageCenterInteraction *messageCenterInteraction = [ApptentiveMessageCenterInteraction messageCenterInteractionFromInteraction:interaction];
		_interaction = [messageCenterInteraction copy];
	}
	return self;
}

- (void)showMessageCenterFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;

	if (!self.viewController) {
		ApptentiveLogError(@"No view controller to present Message Center interface!!");
	} else {
		UINavigationController *navigationController = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"MessageCenterNavigation"];

		ApptentiveMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;
		messageCenter.interaction = self.interaction;

		[viewController presentViewController:navigationController animated:YES completion:nil];
	}
}


@end
