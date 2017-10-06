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

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveInteractionMessageCenterController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"MessageCenter"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	ApptentiveNavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"MessageCenterNavigation"];
	ApptentiveMessageCenterViewController *messageCenter = navigationController.viewControllers.firstObject;

	// TODO: Do this on the background queue?
	ApptentiveConversation *conversation = Apptentive.shared.backend.conversationManager.activeConversation;
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");

	ApptentiveAssertNotNil(Apptentive.shared.backend.conversationManager.messageManager, @"Attempted to present interaction without message manager: %@", self.interaction);
	ApptentiveMessageCenterViewModel *viewModel = [[ApptentiveMessageCenterViewModel alloc] initWithConversation:(ApptentiveConversation *)conversation interaction:self.interaction messageManager:Apptentive.shared.backend.conversationManager.messageManager];
	[viewModel start];

	messageCenter.viewModel = viewModel;

	// Add owning reference to self so we stick around until VC is dismissed.
	messageCenter.interactionController = self;

	Apptentive.shared.backend.presentedMessageCenterViewController = messageCenter;

	self.presentedViewController = navigationController;

	if (viewController) {
		[viewController presentViewController:navigationController animated:YES completion:nil];
	} else {
		[navigationController presentAnimated:YES completion:nil];
	}
}

- (void)dismissInteractionNotification:(NSNotification *)notification {
	[((ApptentiveMessageCenterViewController *)Apptentive.shared.backend.presentedMessageCenterViewController).viewModel stop];

	[super dismissInteractionNotification:notification];
}

@end

NS_ASSUME_NONNULL_END
