//
//  ATInteractionFeedbackDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionFeedbackDialogController.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "ATEngagementBackend.h"
#import "ATMessageCenterMetrics.h"

NSString *const ATInteractionFeedbackDialogEventLabelLaunch = @"launch";
NSString *const ATInteractionFeedbackDialogEventLabelDismiss = @"dismiss";
NSString *const ATInteractionFeedbackDialogEventLabelCancel = @"cancel";
NSString *const ATInteractionFeedbackDialogEventLabelSubmit = @"submit";
NSString *const ATInteractionFeedbackDialogEventLabelSkipViewMessages = @"skip_view_messages";
NSString *const ATInteractionFeedbackDialogEventLabelViewMessages = @"view_messages";

@implementation ATInteractionFeedbackDialogController {
	UIAlertView *didSendFeedbackAlert;
}

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"FeedbackDialog"], @"Attempted to load a FeedbackDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showFeedbackDialogFromViewController:(UIViewController *)viewController {
	
	self.viewController = viewController;
	
	[self.interaction engage:ATInteractionFeedbackDialogEventLabelLaunch fromViewController:self.viewController];
		
	if (!self.viewController) {
		ATLogError(@"No view controller to present feedback interface!!");
	} else {
		//TODO: sending "We're Sorry!" should be its own interaction.
		[self sendSorryMessage];
		
#warning Add a replacement for the Message Center and/or remove the Feedback Dialog Interaction Controller.
		
	}
}

- (void)dealloc {
	if (didSendFeedbackAlert) {
		didSendFeedbackAlert.delegate = nil;
	}	
}

- (void)sendSorryMessage {
	
	/*
	NSDictionary *config = self.interaction.configuration;
	NSString *title = config[@"title"] ?: ATLocalizedString(@"We're Sorry!", @"We're sorry text");
	NSString *body = config[@"body"] ?: ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
	
	[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
	*/
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == didSendFeedbackAlert) {
		if (buttonIndex == 0) { // Cancel
			[self.interaction engage:ATInteractionFeedbackDialogEventLabelSkipViewMessages fromViewController:self.viewController];
			
			//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidCloseNotification object:self userInfo:nil];
		} else if (buttonIndex == 1) { // View Messages
			[self.interaction engage:ATInteractionFeedbackDialogEventLabelViewMessages fromViewController:self.viewController];

			//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouHitMessagesNotification object:self userInfo:nil];
		}
		
		didSendFeedbackAlert.delegate = nil;
		didSendFeedbackAlert = nil;
		
	}
}

@end
