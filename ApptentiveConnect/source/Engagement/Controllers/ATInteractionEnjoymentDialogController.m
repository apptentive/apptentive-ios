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
	NSString *body = config[@"body"] ?: nil;
	NSString *yesText = config[@"yes_text"] ?: ATLocalizedString(@"Yes", @"yes");
	NSString *noText = config[@"no_text"] ?: ATLocalizedString(@"No", @"no");
	
	if (!self.enjoymentDialog) {
		self.enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:body delegate:self cancelButtonTitle:nil otherButtonTitles:noText, yesText, nil];
		[self.enjoymentDialog show];
	}

	[self.interaction engage:ATInteractionEnjoymentDialogEventLabelLaunch fromViewController:self.viewController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.enjoymentDialog) {
		if (buttonIndex == 0) { // no
			if (!self.viewController) {
				UIViewController *candidateVC = [ATUtilities rootViewControllerForCurrentWindow];
				if (candidateVC) {
					self.viewController = candidateVC;
				}
			}
			
			[self.interaction engage:ATInteractionEnjoymentDialogEventLabelNo fromViewController:self.viewController];
		} else if (buttonIndex == 1) { // yes
			[self.interaction engage:ATInteractionEnjoymentDialogEventLabelYes fromViewController:self.viewController];
		}
		
		[self release];
	}
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	_enjoymentDialog.delegate = nil;
	[_enjoymentDialog release], _enjoymentDialog = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
