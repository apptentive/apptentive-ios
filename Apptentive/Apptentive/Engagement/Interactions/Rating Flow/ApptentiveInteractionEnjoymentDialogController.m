//
//  ApptentiveInteractionEnjoymentDialogController.m
//  Apptentive
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionEnjoymentDialogController.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "UIAlertController+Apptentive.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionEnjoymentDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionEnjoymentDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionEnjoymentDialogEventLabelYes = @"yes";
NSString *const ATInteractionEnjoymentDialogEventLabelNo = @"no";


@implementation ApptentiveInteractionEnjoymentDialogController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"EnjoymentDialog"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	self.presentedViewController = [self alertControllerWithInteraction:self.interaction];

	if (self.presentedViewController) {
		if (viewController != nil) {
			[viewController presentViewController:self.presentedViewController
										 animated:YES
									   completion:^{
										 [Apptentive.shared.backend engage:ATInteractionEnjoymentDialogEventLabelLaunch fromInteraction:self.interaction fromViewController:viewController];
									   }];
		} else {
			[(UIAlertController *)self.presentedViewController apptentive_presentAnimated:YES
																			   completion:^{
																				 [Apptentive.shared.backend engage:ATInteractionEnjoymentDialogEventLabelLaunch fromInteraction:self.interaction fromViewController:nil];
																			   }];
		}
	}
}

- (NSString *)title {
	NSString *title = self.interaction.configuration[@"title"] ?: [NSString stringWithFormat:ApptentiveLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [ApptentiveUtilities appName]];

	return title;
}

- (nullable NSString *)body {
	NSString *body = self.interaction.configuration[@"body"] ?: nil;

	return body;
}

- (NSString *)yesText {
	NSString *yesText = self.interaction.configuration[@"yes_text"] ?: ApptentiveLocalizedString(@"Yes", @"yes");

	return yesText;
}

- (NSString *)noText {
	NSString *noText = self.interaction.configuration[@"no_text"] ?: ApptentiveLocalizedString(@"No", @"no");

	return noText;
}

#pragma mark UIAlertController

// NOTE: The action blocks below create a retain cycle. We use this to our
// advantage to make sure the interaction controller sticks around until the
// alert controller is dismissed. At that point we clear the reference to the
// alert controller to break the retain cycle.

- (nullable UIAlertController *)alertControllerWithInteraction:(ApptentiveInteraction *)interaction {
	if (!self.title && !self.body) {
		ApptentiveLogError(@"Skipping display of Enjoyment Dialog that does not have a title or body.");
		return nil;
	}

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.title message:self.body preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:self.noText
														style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction *action) {
														[Apptentive.shared.backend engage:ATInteractionEnjoymentDialogEventLabelNo fromInteraction:self.interaction fromViewController:self.presentingViewController];

														self.presentedViewController = nil;
													  }]];

	[alertController addAction:[UIAlertAction actionWithTitle:self.yesText
														style:UIAlertActionStyleDefault
													  handler:^(UIAlertAction *action) {
														[Apptentive.shared.backend engage:ATInteractionEnjoymentDialogEventLabelYes fromInteraction:self.interaction fromViewController:self.presentingViewController];

														self.presentedViewController = nil;
													  }]];

	return alertController;
}

@end

NS_ASSUME_NONNULL_END
