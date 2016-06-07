//
//  ApptentiveInteractionSurveyController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionSurveyController.h"
#import "Apptentive_Private.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveBackend.h"
#import "ApptentiveSurveyViewController.h"
#import "ApptentiveEngagementBackend.h"

#import "ApptentiveSurvey.h"
#import "ApptentiveSurveyViewModel.h"

NSString *const ATInteractionSurveyEventLabelLaunch = @"launch";


@implementation ApptentiveInteractionSurveyController

- (id)initWithInteraction:(ApptentiveInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"Survey"], @"Attempted to load a SurveyController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showSurveyFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;

	UINavigationController *navigationController = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"SurveyNavigation"];
	ApptentiveSurveyViewModel *viewModel = [[ApptentiveSurveyViewModel alloc] initWithInteraction:self.interaction];
	if (viewModel) {
		ApptentiveSurveyViewController *surveyViewController = navigationController.viewControllers.firstObject;
		surveyViewController.viewModel = viewModel;
		[viewController presentViewController:navigationController animated:YES completion:nil];
	}

	NSDictionary *notificationInfo = @{ApptentiveSurveyIDKey: (self.interaction.identifier ?: [NSNull null])};
	[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveSurveyShownNotification object:nil userInfo:notificationInfo];

	[self.interaction engage:ATInteractionSurveyEventLabelLaunch fromViewController:self.viewController];
}


@end
