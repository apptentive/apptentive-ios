//
//  ATInteractionUIAlertViewController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/26/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertViewController.h"
#import "ATEngagementBackend.h"
#import "ATInteractionInvocation.h"

NSString *const ATInteractionUIAlertViewControllerEventLabelLaunch = @"launch";
NSString *const ATInteractionUIAlertViewControllerEventLabelCancel = @"cancel";
NSString *const ATInteractionUIAlertViewControllerEventLabelDismiss = @"dismiss";
NSString *const ATInteractionUIAlertViewControllerEventLabelInteraction = @"interaction";

@implementation ATInteractionUIAlertViewController

- (void)presentAlertViewWithInteraction:(ATInteraction *)interaction fromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.interaction = interaction;
	self.viewController = viewController;
	
	NSDictionary *config = self.interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Cannot show an Apptentive alert without a title or message.");
		return;
	}
	
	self.alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *title = action[@"label"];
		if (title) {
			[self.alertView addButtonWithTitle:title];
		}
	}
	
	[self.alertView show];
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[self.interaction engage:ATInteractionUIAlertViewControllerEventLabelLaunch fromViewController:self.viewController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *actions = self.interaction.configuration[@"actions"];
	
	NSDictionary *action = [actions objectAtIndex:buttonIndex];
	if (action) {
		NSString *actionType = action[@"action"];
		if ([actionType isEqualToString:@"dismiss"]) {
			[self.interaction engage:ATInteractionUIAlertViewControllerEventLabelDismiss fromViewController:self.viewController];
		} else if ([actionType isEqualToString:@"interaction"]) {
			NSArray *jsonInvocations = action[@"invokes"];
			NSArray *invocations = [ATInteractionInvocation invocationsWithJSONArray:jsonInvocations];
		
			[self.interaction engage:ATInteractionUIAlertViewControllerEventLabelInteraction fromViewController:self.viewController];
			
			ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForInvocations:invocations];
			
			[[ATEngagementBackend sharedBackend] presentInteraction:interaction fromViewController:self.viewController];
		}
	}
	
	[self release];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	_alertView.delegate = nil;
	[_alertView release], _alertView = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
