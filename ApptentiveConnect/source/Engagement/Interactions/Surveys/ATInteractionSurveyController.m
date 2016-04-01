//
//  ATInteractionSurveyController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionSurveyController.h"
#import "Apptentive_Private.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATSurveyViewController.h"
#import "ATEngagementBackend.h"

#import "ATSurvey.h"
#import "ATSurveyViewModel.h"

NSString *const ATInteractionSurveyEventLabelLaunch = @"launch";


@implementation ATInteractionSurveyController

- (id)initWithInteraction:(ATInteraction *)interaction {
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
	ATSurveyViewController *surveyViewController = navigationController.viewControllers.firstObject;
	surveyViewController.viewModel = [[ATSurveyViewModel alloc] initWithInteraction:self.interaction];

	NSDictionary *notificationInfo = @{ATSurveyIDKey: (self.interaction.identifier ?: [NSNull null])};
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyShownNotification object:nil userInfo:notificationInfo];

	[self.interaction engage:ATInteractionSurveyEventLabelLaunch fromViewController:self.viewController];

	[viewController presentViewController:navigationController animated:YES completion:nil];
}


@end
