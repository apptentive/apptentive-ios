//
//  ATInteractionEnjoymentDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 2/18/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionEnjoymentDialogController.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATAppRatingMetrics.h"
#import "ATUtilities.h"
#import "ATEngagementBackend.h"

NSString *const ATInteractionEnjoymentDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionEnjoymentDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionEnjoymentDialogEventLabelYes = @"yes";
NSString *const ATInteractionEnjoymentDialogEventLabelNo = @"no";

@implementation ATInteractionEnjoymentDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to load an EnjoymentDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showEnjoymentDialogFromViewController:(UIViewController *)viewController {
	[self retain];

	self.viewController = viewController;
	
	NSDictionary *config = self.interaction.configuration;
	
	NSString *title = config[@"title"] ?: [NSString stringWithFormat:ATLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [[ATBackend sharedBackend] appName]];
	NSString *body = nil;
	NSString *yesText = config[@"yes_text"] ?: ATLocalizedString(@"Yes", @"yes");
	NSString *noText = config[@"no_text"] ?: ATLocalizedString(@"No", @"no");
	
	if (!self.enjoymentDialog) {
		self.enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:nil otherButtonTitles:noText, yesText, nil];
		[self.enjoymentDialog show];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingDidPromptForEnjoymentNotification object:self];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.enjoymentDialog) {
		if (buttonIndex == 0) { // no
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeNo];
			
			if (!self.viewController) {
				UIViewController *candidateVC = [ATUtilities rootViewControllerForCurrentWindow];
				if (candidateVC) {
					self.viewController = candidateVC;
				}
			}
			
			[self engageEvent:ATInteractionEnjoymentDialogEventLabelNo];
			
		} else if (buttonIndex == 1) { // yes
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
			
			[self engageEvent:ATInteractionEnjoymentDialogEventLabelYes];
		}
		
		[self release];
	}
}

- (void)postNotification:(NSString *)name forButton:(ATAppRatingEnjoymentButtonType)button {
	NSDictionary *userInfo = @{ATAppRatingButtonTypeKey: @(button)};
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (BOOL)engageEvent:(NSString *)eventLabel {
	return [[ATEngagementBackend sharedBackend] engageApptentiveEvent:eventLabel fromInteraction:self.interaction.type fromViewController:self.viewController];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	_enjoymentDialog.delegate = nil;
	[_enjoymentDialog release], _enjoymentDialog = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
