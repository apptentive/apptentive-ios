//
//  ApptentiveInteractionEnjoymentDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 7/15/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionEnjoymentDialogController.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveEngagementBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"

NSString *const ATInteractionEnjoymentDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionEnjoymentDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionEnjoymentDialogEventLabelYes = @"yes";
NSString *const ATInteractionEnjoymentDialogEventLabelNo = @"no";


@interface ApptentiveInteractionEnjoymentDialogController ()

@property (strong, nonatomic) UIAlertController *alertController;

@end


@implementation ApptentiveInteractionEnjoymentDialogController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"EnjoymentDialog"];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	self.alertController = [self alertControllerWithInteraction:self.interaction];

	if (self.alertController) {
		[viewController presentViewController:self.alertController animated:YES completion:^{
			[self.interaction engage:ATInteractionEnjoymentDialogEventLabelLaunch fromViewController:self.presentingViewController];
		}];
	}
}

- (NSString *)title {
	NSString *title = self.interaction.configuration[@"title"] ?: [NSString stringWithFormat:ApptentiveLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [[Apptentive sharedConnection].backend appName]];

	return title;
}

- (NSString *)body {
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

- (UIAlertController *)alertControllerWithInteraction:(ApptentiveInteraction *)interaction {
	if (!self.title && !self.body) {
		ApptentiveLogError(@"Skipping display of Enjoyment Dialog that does not have a title or body.");
		return nil;
	}

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.title message:self.body preferredStyle:UIAlertControllerStyleAlert];

	[alertController addAction:[UIAlertAction actionWithTitle:self.noText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		if (!self.presentingViewController) {
			UIViewController *candidateVC = [ApptentiveUtilities rootViewControllerForCurrentWindow];
			if (candidateVC) {
				self.presentingViewController = candidateVC;
			}
		}
		
        [self.interaction engage:ATInteractionEnjoymentDialogEventLabelNo fromViewController:self.presentingViewController];
	}]];

	[alertController addAction:[UIAlertAction actionWithTitle:self.yesText style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.interaction engage:ATInteractionEnjoymentDialogEventLabelYes fromViewController:self.presentingViewController];
	}]];

	return alertController;
}

@end
