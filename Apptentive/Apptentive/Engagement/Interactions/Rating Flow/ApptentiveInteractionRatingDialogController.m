//
//  ApptentiveInteractionRatingDialogController.m
//  Apptentive
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionRatingDialogController.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveBackend+Engagement.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"
#import "UIAlertController+Apptentive.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionRatingDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionRatingDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionRatingDialogEventLabelRate = @"rate";
NSString *const ATInteractionRatingDialogEventLabelRemind = @"remind";
NSString *const ATInteractionRatingDialogEventLabelDecline = @"decline";


@implementation ApptentiveInteractionRatingDialogController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"RatingDialog"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	self.presentedViewController = [self alertControllerWithInteraction:self.interaction];

	if (self.presentedViewController) {
		if (viewController != nil) {
			[viewController presentViewController:self.presentedViewController animated:YES completion:^{
				[self.interaction engage:ATInteractionRatingDialogEventLabelLaunch fromViewController:viewController];
			}];
		} else {
			[(UIAlertController *)self.presentedViewController apptentive_presentAnimated:YES completion:^{
				[self.interaction engage:ATInteractionRatingDialogEventLabelLaunch fromViewController:nil];
			}];
		}
	}
}

- (NSString *)title {
	NSString *title = self.interaction.configuration[@"title"] ?: ApptentiveLocalizedString(@"Thank You", @"Rate app title.");

	return title;
}

- (NSString *)body {
	NSString *body = self.interaction.configuration[@"body"] ?: [NSString stringWithFormat:ApptentiveLocalizedString(@"We're so happy to hear that you love %@! It'd be really helpful if you rated us. Thanks so much for spending some time with us.", @"Rate app message. Parameter is app name."), [ApptentiveUtilities appName]];

	return body;
}

- (NSString *)rateText {
	NSString *rateText = self.interaction.configuration[@"rate_text"] ?: [NSString stringWithFormat:ApptentiveLocalizedString(@"Rate %@", @"Rate app button title"), [ApptentiveUtilities appName]];

	return rateText;
}

- (NSString *)declineText {
	NSString *declineText = self.interaction.configuration[@"decline_text"] ?: ApptentiveLocalizedString(@"No Thanks", @"cancel title for app rating dialog");

	return declineText;
}

- (NSString *)remindText {
	NSString *remindText = self.interaction.configuration[@"remind_text"] ?: ApptentiveLocalizedString(@"Remind Me Later", @"Remind me later button title");

	return remindText;
}

#pragma mark UIAlertController

// NOTE: The action blocks below create a retain cycle. We use this to our
// advantage to make sure the interaction controller sticks around until the
// alert controller is dismissed. At that point we clear the reference to the
// alert controller to break the retain cycle.

- (nullable UIAlertController *)alertControllerWithInteraction:(ApptentiveInteraction *)interaction {
	if (!self.title && !self.body) {
		ApptentiveLogError(@"Skipping display of Rating Dialog that does not have a title or body.");
		return nil;
	}

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.title message:self.body preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:self.rateText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self.interaction engage:ATInteractionRatingDialogEventLabelRate fromViewController:self.presentingViewController];

		self.presentedViewController = nil;
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:self.remindText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		[self.interaction engage:ATInteractionRatingDialogEventLabelRemind fromViewController:self.presentingViewController];

		self.presentedViewController = nil;
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:self.declineText style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[self.interaction engage:ATInteractionRatingDialogEventLabelDecline fromViewController:self.presentingViewController];

		self.presentedViewController = nil;
	}]];

	return alertController;
}

@end

NS_ASSUME_NONNULL_END
