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

NSString *const ATInteractionEnjoymentDialogNo = @"ATInteractionEnjoymentDialogNo";
NSString *const ATInteractionEnjoymentDialogYes = @"ATInteractionEnjoymentDialogYes";

@implementation ATInteractionEnjoymentDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to load an EnjoymentDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = interaction;
	}
	return self;
}

- (void)showEnjoymentDialogFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;
	
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
			
			/*
			if (!self.viewController) {
				ATLogError(@"No view controller to present feedback interface!!");
			} else {
				
				//TODO: move to FeedbackDialog interaction
				NSString *title = ATLocalizedString(@"We're Sorry!", @"We're sorry text");
				NSString *body = ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
				[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
				[[ATBackend sharedBackend] presentIntroDialogFromViewController:self.viewController withTitle:title prompt:body placeholderText:nil];
			}
			*/
			
			[[ATConnect sharedConnection] engage:ATInteractionEnjoymentDialogNo fromViewController:self.viewController];
			
		} else if (buttonIndex == 1) { // yes
			[self postNotification:ATAppRatingDidClickEnjoymentButtonNotification forButton:ATAppRatingEnjoymentButtonTypeYes];
			
			[[ATConnect sharedConnection] engage:ATInteractionEnjoymentDialogYes fromViewController:self.viewController];
		}
	}
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
