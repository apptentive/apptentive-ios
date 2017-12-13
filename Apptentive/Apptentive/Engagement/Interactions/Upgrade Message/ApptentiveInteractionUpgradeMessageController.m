//
//  ApptentiveInteractionUpgradeMessageController.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/18/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionUpgradeMessageController.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionUpgradeMessageViewController.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionUpgradeMessageEventLabelLaunch = @"launch";
NSString *const ATInteractionUpgradeMessageEventLabelDismiss = @"dismiss";


@implementation ApptentiveInteractionUpgradeMessageController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"UpgradeMessage"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	ApptentiveNavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"UpgradeMessageNavigation"];
	ApptentiveInteractionUpgradeMessageViewController *result = (ApptentiveInteractionUpgradeMessageViewController *)navigationController.viewControllers.firstObject;

	result.upgradeMessageInteraction = self.interaction;

	// Add owning reference to self so we stick around until VC is dismissed.
	result.interactionController = self;

	self.presentedViewController = navigationController;

	if (viewController != nil) {
		[viewController presentViewController:navigationController animated:YES completion:nil];
	} else {
		[navigationController presentAnimated:YES completion:nil];
	}

	[Apptentive.shared.backend engage:ATInteractionUpgradeMessageEventLabelLaunch fromInteraction:result.upgradeMessageInteraction fromViewController:viewController];
}

- (NSString *)programmaticDismissEventLabel {
	return ATInteractionUpgradeMessageEventLabelDismiss;
}

@end

NS_ASSUME_NONNULL_END
