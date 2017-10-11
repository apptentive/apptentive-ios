//
//  ApptentiveInteractionSurveyController.m
//  Apptentive
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionSurveyController.h"
#import "Apptentive_Private.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveBackend.h"
#import "ApptentiveSurveyViewController.h"
#import "ApptentiveBackend+Engagement.h"

#import "ApptentiveSurvey.h"
#import "ApptentiveSurveyViewModel.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionSurveyEventLabelLaunch = @"launch";


@implementation ApptentiveInteractionSurveyController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"Survey"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	ApptentiveNavigationController *navigationController = [[ApptentiveUtilities storyboard] instantiateViewControllerWithIdentifier:@"SurveyNavigation"];
	ApptentiveSurveyViewModel *viewModel = [[ApptentiveSurveyViewModel alloc] initWithInteraction:self.interaction];
	if (viewModel) {
		ApptentiveSurveyViewController *surveyViewController = navigationController.viewControllers.firstObject;

		surveyViewController.viewModel = viewModel;

		// Add owning reference to self so we stick around until VC is dismissed
		surveyViewController.interactionController = self;

		self.presentedViewController = navigationController;

		if (viewController != nil) {
			[viewController presentViewController:navigationController animated:YES completion:nil];
		} else {
			[navigationController presentAnimated:YES completion:nil];
		}
	}

	ApptentiveAssertNotNil(self.interaction.identifier, @"Interaction identifier is nil");
	if (self.interaction.identifier != nil) {
		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveSurveyShownNotification object:@{ApptentiveSurveyIDKey: self.interaction.identifier}];
	}
	
	[self.interaction engage:ATInteractionSurveyEventLabelLaunch fromViewController:viewController];
}

@end

NS_ASSUME_NONNULL_END
