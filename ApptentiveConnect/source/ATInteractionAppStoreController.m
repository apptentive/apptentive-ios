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

// TODO: Remove, soon. All info should come from interaction's configuration.
#import "ATAppRatingFlow.h"
#import "ATAppRatingFlow_Private.h"

@implementation ATInteractionAppStoreController

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

@end
