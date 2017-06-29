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

	ApptentiveConversation *conversation = Apptentive.shared.backend.conversationManager.activeConversationTemp;
    ApptentiveAssertNotNil(conversation, @"Conversation is nil");

    ApptentiveAssertNotNil(Apptentive.shared.backend.conversationManager.messageManager, @"Attempted to present interaction without message manager: %@", self.interaction);
	ApptentiveMessageCenterViewModel *viewModel = [[ApptentiveMessageCenterViewModel alloc] initWithConversation:(ApptentiveConversation *)conversation interaction:self.interaction messageManager:Apptentive.shared.backend.conversationManager.messageManager];
	[viewModel start];

	messageCenter.viewModel = viewModel;

	Apptentive.shared.backend.presentedMessageCenterViewController = messageCenter;

	[viewController presentViewController:navigationController animated:YES completion:nil];
}

@end
