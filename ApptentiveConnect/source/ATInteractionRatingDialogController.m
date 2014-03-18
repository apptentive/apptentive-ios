//
//  ATInteractionRatingDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionRatingDialogController.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATAppRatingMetrics.h"
#import "ATUtilities.h"

// TODO: Remove, soon. All info should come from interaction's configuration.
#import "ATAppRatingFlow.h"
#import "ATAppRatingFlow_Private.h"

NSString *const ATInteractionRatingDialogRate = @"ATInteractionRatingDialogRate";
NSString *const ATInteractionRatingDialogRemind = @"ATInteractionRatingDialogRemind";
NSString *const ATInteractionRatingDialogDecline = @"ATInteractionRatingDialogDecline";

@implementation ATInteractionRatingDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"RatingDialog"], @"Attempted to load a Rating Dialog with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showRatingDialogFromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.viewController = viewController;
	
	NSDictionary *config = self.interaction.configuration;

	NSString *title = config[@"title"] ?: ATLocalizedString(@"Thank You", @"Rate app title.");
	NSString *message = config[@"body"] ?: [NSString stringWithFormat:ATLocalizedString(@"We're so happy to hear that you love %@! It'd be really helpful if you rated us. Thanks so much for spending some time with us.", @"Rate app message. Parameter is app name."), [[ATBackend sharedBackend] appName]];
	NSString *rateAppTitle = config[@"rate_text"] ?: [NSString stringWithFormat:ATLocalizedString(@"Rate %@", @"Rate app button title"), [[ATBackend sharedBackend] appName]];
	NSString *noThanksTitle = config[@"no_text"] ?: ATLocalizedString(@"No Thanks", @"cancel title for app rating dialog");
	NSString *remindMeTitle = config[@"remind_text"] ?: ATLocalizedString(@"Remind Me Later", @"Remind me later button title");
	
	if (!self.ratingDialog) {
		self.ratingDialog = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:noThanksTitle otherButtonTitles:rateAppTitle, remindMeTitle, nil];
		[self.ratingDialog show];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingDidPromptForRatingNotification object:nil];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView == self.ratingDialog) {
		if (buttonIndex == 1) { // rate
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRateApp];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ATAppRatingFlowUserAgreedToRateAppNotification object:nil];
			
			[[ATConnect sharedConnection] engage:ATInteractionRatingDialogRate fromViewController:self.viewController];
						
			[self openAppStoreToRateApp];
			
		} else if (buttonIndex == 2) { // remind later
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeRemind];
			
			[[ATConnect sharedConnection] engage:ATInteractionRatingDialogRemind fromViewController:self.viewController];
		} else if (buttonIndex == 0) { // no thanks
			[self postNotification:ATAppRatingDidClickRatingButtonNotification forButton:ATAppRatingButtonTypeNo];
			
			[[ATConnect sharedConnection] engage:ATInteractionRatingDialogDecline fromViewController:self.viewController];
		}
		
		[self release];
	}
}

- (void)postNotification:(NSString *)name forButton:(ATAppRatingButtonType)button {
	NSDictionary *userInfo = @{ATAppRatingButtonTypeKey: @(button)};
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
}

- (void)openAppStoreToRateApp {
#if TARGET_OS_IPHONE
#	if TARGET_IPHONE_SIMULATOR
	[self showUnableToOpenAppStoreDialog];
#	else
	if ([self shouldOpenAppStoreViaStoreKit]) {
		[self openAppStoreViaStoreKit];
	}
	else {
		[self openAppStoreViaURL];
	}
#	endif
	
#elif TARGET_OS_MAC
	[self openMacAppStore];
#endif
}

#if TARGET_OS_IPHONE
- (void)showUnableToOpenAppStoreDialog {
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Oops!", @"Unable to load the App Store title") message:ATLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message") delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil] autorelease];
	[errorAlert show];
}
#endif

// TODO: method of opening App Store should come from interaction's configuration.
- (BOOL)shouldOpenAppStoreViaStoreKit {	
	return ([SKStoreProductViewController class] != NULL && [self appID] && ![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]);
}

// TODO: rating URL should come from the interaction's configuration.
- (NSURL *)URLForRatingApp {
	NSString *URLString = nil;
	NSString *URLStringFromPreferences = [[NSUserDefaults standardUserDefaults] objectForKey:ATAppRatingReviewURLPreferenceKey];
	if (URLStringFromPreferences == nil) {
#if TARGET_OS_IPHONE
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"6.0"]) {
			URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode], [self appID]];
		} else {
			URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [self appID]];
		}
#elif TARGET_OS_MAC
		URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", [self appID]];
#endif
	} else {
		URLString = URLStringFromPreferences;
	}
	return [NSURL URLWithString:URLString];
}

- (void)openAppStoreViaURL {
	if ([self appID]) {
		NSURL *url = [self URLForRatingApp];
		if (![[UIApplication sharedApplication] canOpenURL:url]) {
			ATLogError(@"No application can open the URL: %@", url);
			[self showUnableToOpenAppStoreDialog];
		}
		else {
			[[UIApplication sharedApplication] openURL:url];
		}
	}
	else {
		[self showUnableToOpenAppStoreDialog];
	}
}

- (void)openAppStoreViaStoreKit {
	if ([SKStoreProductViewController class] != NULL && [self appID]) {
		SKStoreProductViewController *vc = [[[SKStoreProductViewController alloc] init] autorelease];
		vc.delegate = self;
		[vc loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:self.appID} completionBlock:^(BOOL result, NSError *error) {
			if (error) {
				ATLogError(@"Error loading product view: %@", error);
				[self showUnableToOpenAppStoreDialog];
			} else {
				//UIViewController *presentingVC = [ATUtilities rootViewControllerForCurrentWindow];
				
				UIViewController *presentingVC = self.viewController;
				
				
				if ([presentingVC respondsToSelector:@selector(presentViewController:animated:completion:)]) {
					[presentingVC presentViewController:vc animated:YES completion:^{}];
				} else {
#					pragma clang diagnostic push
#					pragma clang diagnostic ignored "-Wdeprecated-declarations"
					[presentingVC presentModalViewController:vc animated:YES];
#					pragma clang diagnostic pop
				}
			}
		}];
	}
	else {
		[self showUnableToOpenAppStoreDialog];
	}
}

- (void)openMacAppStore {
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
	NSURL *url = [self URLForRatingApp];
	[[NSWorkspace sharedWorkspace] openURL:url];
#endif
}

// TODO: appID should come from the interaction's configuration.
- (NSString *)appID {
	return [ATAppRatingFlow sharedRatingFlow].appID;
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_ratingDialog release], _ratingDialog = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
