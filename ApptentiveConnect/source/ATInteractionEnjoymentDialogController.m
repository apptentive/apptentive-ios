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

@implementation ATInteractionEnjoymentDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to load an EnjoymentDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_enjoymentDialogInteraction = interaction;
	}
	return self;
}

- (void)showRatingFlowFromViewController:(UIViewController *)viewController {
	
	//TODO: appName should come from server.
	NSString *title = [NSString stringWithFormat:ATLocalizedString(@"Do you love %@?", @"Title for enjoyment alert view. Parameter is app name."), [[ATBackend sharedBackend] appName]];
	
	if (!self.enjoymentDialog) {
		self.enjoymentDialog = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:ATLocalizedString(@"No", @"no"), ATLocalizedString(@"Yes", @"yes"), nil];
		[self.enjoymentDialog show];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingDidPromptForEnjoymentNotification object:self];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.enjoymentDialog) {
		[self enjoymentDialogClickedButtonAtIndex:buttonIndex];
	} else if (alertView == self.ratingDialog) {
		[self ratingDialogClickedButtonAtIndex:buttonIndex];
	}
}

- (void)enjoymentDialogClickedButtonAtIndex:(NSInteger)buttonIndex {
	
	[self.enjoymentDialog release], self.enjoymentDialog = nil;
	if (buttonIndex == 0) { // no
		[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeNo];
		//[self setUserDislikesThisVersion];
		
		if (!self.viewController) {
			UIViewController *candidateVC = [self rootViewControllerForCurrentWindow];
			if (candidateVC) {
				self.viewController = candidateVC;
			}
		}
		if (!self.viewController) {
			ATLogError(@"No view controller to present feedback interface!!");
		} else {
			NSString *title = ATLocalizedString(@"We're Sorry!", @"We're sorry text");
			NSString *body = ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
			[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
			[[ATBackend sharedBackend] presentIntroDialogFromViewController:self.viewController withTitle:title prompt:body placeholderText:nil];
		}
	} else if (buttonIndex == 1) { // yes
		[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
		[self showRatingDialog:self.viewController];
	}
}

- (void)showRatingDialog:(UIViewController *)vc
{
	NSString *title = ATLocalizedString(@"Thank You", @"Rate app title.");
	NSString *message = [NSString stringWithFormat:ATLocalizedString(@"We're so happy to hear that you love %@! It'd be really helpful if you rated us. Thanks so much for spending some time with us.", @"Rate app message. Parameter is app name."), [[ATBackend sharedBackend] appName]];
	NSString *rateAppTitle = [NSString stringWithFormat:ATLocalizedString(@"Rate %@", @"Rate app button title"), [[ATBackend sharedBackend] appName]];
	NSString *noThanksTitle = ATLocalizedString(@"No Thanks", @"cancel title for app rating dialog");
	NSString *remindMeTitle = ATLocalizedString(@"Remind Me Later", @"Remind me later button title");

	if (!self.ratingDialog) {
		self.ratingDialog = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:noThanksTitle otherButtonTitles:rateAppTitle, remindMeTitle, nil];
		[self.ratingDialog show];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingDidPromptForRatingNotification object:nil];
	//[self setRatingDialogWasShown];
}

- (void)ratingDialogClickedButtonAtIndex:(NSInteger)buttonIndex {
	[self.ratingDialog release], self.ratingDialog = nil;
	if (buttonIndex == 1) { // rate
		[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRateApp];
		//[self userAgreedToRateApp];
	} else if (buttonIndex == 2) { // remind later
		[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRemind];
		//[self setRatingDialogWasShown];
	} else if (buttonIndex == 0) { // no thanks
		[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeNo];
		//[self setDeclinedToRateThisVersion];
	}
	self.viewController = nil;
}

- (UIViewController *)rootViewControllerForCurrentWindow {
	UIWindow *window = nil;
	if (self.viewController && self.viewController.view && self.viewController.view.window) {
		window = self.viewController.view.window;
	} else {
		for (UIWindow *tmpWindow in [[UIApplication sharedApplication] windows]) {
			if ([[tmpWindow screen] isEqual:[UIScreen mainScreen]] && [tmpWindow isKeyWindow]) {
				window = tmpWindow;
				break;
			}
		}
	}
	if (window && [window respondsToSelector:@selector(rootViewController)]) {
		UIViewController *vc = [window rootViewController];
		if ([vc respondsToSelector:@selector(presentedViewController)] && [vc presentedViewController]) {
			return [vc presentedViewController];
		}
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		if ([vc respondsToSelector:@selector(modalViewController)] && [vc modalViewController]) {
			return [vc modalViewController];
		}
#		pragma clang diagnostic pop
		return vc;
	} else {
		return nil;
	}
}

- (void)postNotification:(NSString *)name forButton:(int)button {
	NSDictionary *userInfo = @{ATAppRatingButtonTypeKey: @(button)};
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

@end
