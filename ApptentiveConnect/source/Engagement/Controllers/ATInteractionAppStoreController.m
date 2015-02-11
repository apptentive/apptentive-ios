//
//  ATInteractionAppStoreController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionAppStoreController.h"
#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "ATInteraction.h"
#import "ATEngagementBackend.h"

NSString *const ATInteractionAppStoreRatingEventLabelLaunch = @"launch";
NSString *const ATInteractionAppStoreRatingEventLabelOpenAppStoreURL = @"open_app_store_url";
NSString *const ATInteractionAppStoreRatingEventLabelOpenStoreKit = @"open_store_kit";
NSString *const ATInteractionAppStoreRatingEventLabelOpenMacAppStore = @"open_mac_app_store";
NSString *const ATInteractionAppStoreRatingEventLabelUnableToRate = @"unable_to_rate";

@implementation ATInteractionAppStoreController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"AppStoreRating"], @"Attempted to load an AppStoreRating interaction with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)openAppStoreFromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.viewController = viewController;
	
	[self openAppStoreToRateApp];
}

- (NSString *)appID {
	NSString *appID = self.interaction.configuration[@"store_id"];
	if (!appID) {
		appID = [ATConnect sharedConnection].appID;
	}
		
	return appID;
}

- (void)openAppStoreToRateApp {
	NSString *method = self.interaction.configuration[@"method"];
	
	if ([method isEqualToString:@"app_store"]) {
		[self openAppStoreViaURL];
	} else if ([method isEqualToString:@"store_kit"]) {
		[self openAppStoreViaStoreKit];
	} else if ([method isEqualToString:@"mac_app_store"]) {
		[self openMacAppStore];
	} else {
		[self legacyOpenAppStoreToRateApp];
	}
}

- (void)legacyOpenAppStoreToRateApp {
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
	[self.interaction engage:ATInteractionAppStoreRatingEventLabelUnableToRate fromViewController:self.viewController];

	NSString *title;
	NSString *message;
	NSString *cancelButtonTitle;
#	if TARGET_IPHONE_SIMULATOR
	title = @"Unable to open the App Store";
	message = @"The iOS Simulator is unable to open the App Store app. Please try again on a real iOS device.";
	cancelButtonTitle = @"OK";
#	else
	title = ATLocalizedString(@"Oops!", @"Unable to load the App Store title");
	message = ATLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message");
	cancelButtonTitle = ATLocalizedString(@"OK", @"OK button title");
#	endif
	
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil] autorelease];
	[errorAlert show];
}
#endif

- (BOOL)shouldOpenAppStoreViaStoreKit {
	return ([SKStoreProductViewController class] != NULL && [self appID] && ![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]);
}

- (NSURL *)URLForRatingApp {
	NSString *urlString = self.interaction.configuration[@"url"];

	NSURL *ratingURL = (urlString) ? [NSURL URLWithString:urlString] : [self legacyURLForRatingApp];

	return ratingURL;
}

- (NSURL *)legacyURLForRatingApp {
	NSString *URLString = nil;
	
#if TARGET_OS_IPHONE
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"7.1"]) {
		URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [self appID]];
	} else if ([ATUtilities osVersionGreaterThanOrEqualTo:@"6.0"]) {
		URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode], [self appID]];
	} else {
		URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [self appID]];
	}
#elif TARGET_OS_MAC
	URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", [self appID]];
#endif
	
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
			[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenAppStoreURL fromViewController:self.viewController];
			
			[[UIApplication sharedApplication] openURL:url];
			
			[self release];
		}
	}
	else {
		ATLogError(@"Could not open App Store because App ID is not set. Set the `appID` property locally, or configure it remotely via the Apptentive dashboard.");
		
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
				[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenStoreKit fromViewController:self.viewController];
				
				UIViewController *presentingVC = self.viewController;

				if (!presentingVC) {
					ATLogError(@"Attempting to open the App Store via StoreKit from a nil View Controller!");
				}
				else if ([presentingVC respondsToSelector:@selector(presentViewController:animated:completion:)]) {
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

#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)productViewController {
	if ([productViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
		[productViewController dismissViewControllerAnimated:YES completion:NULL];
	} else {
#		pragma clang diagnostic push
#		pragma clang diagnostic ignored "-Wdeprecated-declarations"
		[productViewController dismissModalViewControllerAnimated:YES];
#		pragma clang diagnostic pop
	}
	
	[self release];
}

#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//Unable to open app store
	
	[self release];
}

- (void)openMacAppStore {
	[self.interaction engage:ATInteractionAppStoreRatingEventLabelOpenMacAppStore fromViewController:self.viewController];
	
#if TARGET_OS_IPHONE
#elif TARGET_OS_MAC
	NSURL *url = [self URLForRatingApp];
	[[NSWorkspace sharedWorkspace] openURL:url];
	
	[self release];
#endif
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
