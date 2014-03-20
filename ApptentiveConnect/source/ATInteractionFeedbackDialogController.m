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
#import "ATMessagePanelNewUIViewController.h"
#import "ATUtilities.h"

NSString *const ATInteractionFeedbackDialogLaunch = @"com.apptentive#FeebackDialog#launch";
NSString *const ATInteractionFeedbackDialogDismiss = @"com.apptentive#FeebackDialog#dismiss";
NSString *const ATInteractionFeedbackDialogCancel = @"com.apptentive#FeebackDialog#cancel";
NSString *const ATInteractionFeedbackDialogSubmit = @"com.apptentive#FeebackDialog#submit";
NSString *const ATInteractionFeedbackDialogSkipViewMessages = @"com.apptentive#FeedbackDialog#skip_view_messages";
NSString *const ATInteractionFeedbackDialogViewMessages = @"com.apptentive#FeedbackDialog#view_messages";

@implementation ATInteractionFeedbackDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"FeedbackDialog"], @"Attempted to load a FeedbackDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showFeedbackDialogFromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.viewController = viewController;
	
	[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogLaunch fromViewController:self.viewController];
		
	if (!self.viewController) {
		ATLogError(@"No view controller to present feedback interface!!");
	} else {
		//TODO: sending "We're Sorry!" should be its own interaction.
		[self sendSorryMessage];
		
		ATMessagePanelViewController *messagePanel;
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.0"]) {
			messagePanel = [[ATMessagePanelNewUIViewController alloc] initWithDelegate:self];
		}
		else {
			messagePanel = [[ATMessagePanelViewController alloc] initWithDelegate:self];
		}
		
		NSDictionary *config = self.interaction.configuration;
		NSString *title = config[@"title"] ?: ATLocalizedString(@"We're Sorry!", @"We're sorry text");
		messagePanel.promptTitle = title;
		
		NSString *body = config[@"body"] ?: ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
		messagePanel.promptText = body;
		
		BOOL showEmailAddressField = [config[@"ask_for_email"] boolValue] ?: YES;
		messagePanel.showEmailAddressField = showEmailAddressField;
		
		[messagePanel presentFromViewController:self.viewController animated:YES];
	}
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

- (void)sendSorryMessage {
	NSDictionary *config = self.interaction.configuration;
	NSString *title = config[@"title"] ?: ATLocalizedString(@"We're Sorry!", @"We're sorry text");
	NSString *body = config[@"body"] ?: ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
	
	[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
}

- (void)messagePanelDidCancel:(ATMessagePanelViewController *)messagePanel {
	[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogCancel fromViewController:self.viewController];
	
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didSendMessage:(NSString *)message withEmailAddress:(NSString *)emailAddress {
	[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogSubmit fromViewController:self.viewController];
	
}

- (void)messagePanel:(ATMessagePanelViewController *)messagePanel didDismissWithAction:(ATMessagePanelDismissAction)action {
	[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogDismiss fromViewController:self.viewController];
	
	if (action == ATMessagePanelDidSendMessage) {
		if (!self.didSendFeedbackAlert) {
			NSDictionary *config = self.interaction.configuration;
			
			NSString *alertTitle = config[@"thank_you_title"] ?: ATLocalizedString(@"Thanks!", nil);
			NSString *alertMessage = config[@"thank_you_body"] ?: ATLocalizedString(@"Your response has been saved in the Message Center, where you'll be able to view replies and send us other messages.", @"Message panel sent message confirmation dialog text");
			NSString *cancelButtonTitle = config[@"thank_you_close_text"] ?: ATLocalizedString(@"Close", @"Close alert view title");
			NSString *otherButtonTitle = config[@"thank_you_view_messages_text"] ?: ATLocalizedString(@"View Messages", @"View messages button title");

			BOOL messageCenterEnabled = [config[@"enable_message_center"] boolValue];
			if (!messageCenterEnabled) {
				otherButtonTitle = nil;
			}
			
			self.didSendFeedbackAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitle, nil];
			[self.didSendFeedbackAlert show];
			
			//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidShowNotification object:self userInfo:nil];
		}
	} else {
		[self release];
	}
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.didSendFeedbackAlert) {
		if (buttonIndex == 0) { // Cancel
			[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogSkipViewMessages fromViewController:self.viewController];
			
			//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouDidCloseNotification object:self userInfo:nil];
		} else if (buttonIndex == 1) { // View Messages
			[[ATConnect sharedConnection] engage:ATInteractionFeedbackDialogViewMessages fromViewController:self.viewController];

			//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroThankYouHitMessagesNotification object:self userInfo:nil];
		}
		
		self.didSendFeedbackAlert.delegate = nil;
		[self.didSendFeedbackAlert release], self.didSendFeedbackAlert = nil;
		
		[self release];
	}
}

- (NSString *)initialEmailAddressForMessagePanel:(ATMessagePanelViewController *)messagePanel {
	NSString *email = [ATConnect sharedConnection].initialUserEmailAddress;
	
	if ([ATPersonInfo personExists]) {
		email = [ATPersonInfo currentPerson].emailAddress;
	}
	
	return email;
}

@end
