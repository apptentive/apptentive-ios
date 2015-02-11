//
//  ATInteractionSurveyController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionSurveyController.h"
#import "ATConnect.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATSurveyParser.h"
#import "ATSurveyViewController.h"
#import "ATEngagementBackend.h"

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
	[self retain];
	
	self.viewController = viewController;
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	ATSurvey *survey = [parser surveyWithInteraction:self.interaction];
	[parser release];
	
	ATSurveyViewController *vc = [[ATSurveyViewController alloc] initWithSurvey:survey];
	vc.interaction = self.interaction;
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	NSDictionary *notificationInfo = @{ATSurveyIDKey: (survey.identifier ?: [NSNull null])};
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyShownNotification object:nil userInfo:notificationInfo];
	
	[self.interaction engage:ATInteractionSurveyEventLabelLaunch fromViewController:self.viewController];
	
	[viewController presentViewController:nc animated:YES completion:^{}];
	[nc release];
	[vc release];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
