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

NSString *const ATInteractionEnjoymentDialogNo = @"com.apptentive/enjoyment_dialog/no";
NSString *const ATInteractionEnjoymentDialogYes = @"com.apptentive/enjoyment_dialog/yes";

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
	
	NSString *title = config[@"body"] ?: [NSString stringWithFormat:ATLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [[ATBackend sharedBackend] appName]];
	NSString *yesText = config[@"yes_text"] ?: ATLocalizedString(@"Yes", @"yes");
	NSString *noText = config[@"no_text"] ?: ATLocalizedString(@"No", @"no");
	
	if (!self.enjoymentDialog) {
		self.enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:noText, yesText, nil];
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
			
			[[ATConnect sharedConnection] engage:ATInteractionEnjoymentDialogNo fromViewController:self.viewController];
			
		} else if (buttonIndex == 1) { // yes
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
			
			[[ATConnect sharedConnection] engage:ATInteractionEnjoymentDialogYes fromViewController:self.viewController];
		}
		
		[self release];
	}
}

- (void)postNotification:(NSString *)name forButton:(ATAppRatingEnjoymentButtonType)button {
	NSDictionary *userInfo = @{ATAppRatingButtonTypeKey: @(button)};
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_enjoymentDialog release], _enjoymentDialog = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
