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

@interface ATInteractionMessageCenterController ()

@property (nonatomic, strong, readonly) ATMessageCenterInteraction *interaction;
@property (nonatomic, strong) UIViewController *viewController;

@end

@implementation ATInteractionMessageCenterController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"MessageCenter"], @"Attempted to load a MessageCenterController with an interaction of type: %@", interaction.type);
	
	self = [super init];
	if (self != nil) {
		ATMessageCenterInteraction *messageCenterInteraction = [ATMessageCenterInteraction messageCenterInteractionFromInteraction:interaction];
		_interaction = [messageCenterInteraction copy];
	}
	return self;
}

- (void)showMessageCenterFromViewController:(UIViewController *)viewController {
	
	self.viewController = viewController;
	
	if (!self.viewController) {
		ATLogError(@"No view controller to present Message Center interface!!");
	} else {
		UINavigationController *navigationController = [[ATConnect storyboard] instantiateViewControllerWithIdentifier:@"MessageCenterNavigation"];
		
        ATMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;
		messageCenter.interaction = self.interaction;
		
		[viewController presentViewController:navigationController animated:YES completion:nil];
	}
}


@end
