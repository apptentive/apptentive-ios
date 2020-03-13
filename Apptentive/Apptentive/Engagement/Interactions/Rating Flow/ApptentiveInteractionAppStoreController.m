//
//  ApptentiveInteractionAppStoreController.m
//  Apptentive
//
//  Created by Peter Kamb on 3/26/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionAppStoreController.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveStoreProductViewController.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "UIAlertController+Apptentive.h"
#import "ApptentiveURLOpener.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionAppStoreRatingEventLabelLaunch = @"launch";
NSString *const ATInteractionAppStoreRatingEventLabelOpenAppStoreURL = @"open_app_store_url";
NSString *const ATInteractionAppStoreRatingEventLabelOpenStoreKit = @"open_store_kit";
NSString *const ATInteractionAppStoreRatingEventLabelOpenMacAppStore = @"open_mac_app_store";
NSString *const ATInteractionAppStoreRatingEventLabelUnableToRate = @"unable_to_rate";


@implementation ApptentiveInteractionAppStoreController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"AppStoreRating"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	[self openAppStoreToRateApp];
}

- (NSString *)appID {
	NSString *appID = self.interaction.configuration[@"store_id"];
	if (appID.length == 0) {
		appID = [Apptentive sharedConnection].appID;
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
#if TARGET_IPHONE_SIMULATOR
	[self showUnableToOpenAppStoreDialog];
#else
	if ([self shouldOpenAppStoreViaStoreKit]) {
		[self openAppStoreViaStoreKit];
	} else {
		[self openAppStoreViaURL];
	}
#endif
}

- (void)showUnableToOpenAppStoreDialog {
	[Apptentive.shared.backend engage:ATInteractionAppStoreRatingEventLabelUnableToRate fromInteraction:self.interaction fromViewController:self.presentingViewController];

	NSString *title;
	NSString *message;
	NSString *cancelButtonTitle;
#if TARGET_IPHONE_SIMULATOR
	title = ApptentiveLocalizedString(@"Unable to open the App Store", @"iOS simulator unable to load the App store title");
	message = ApptentiveLocalizedString(@"The iOS Simulator is unable to open the App Store app. Please try again on a real iOS device.", @"iOS simulator unable to load the App store message");
#else
	title = ApptentiveLocalizedString(@"Oops!", @"Unable to load the App Store title");
	message = ApptentiveLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message");
#endif
	cancelButtonTitle = ApptentiveLocalizedString(@"OK", @"OK button title");


	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];

	if (self.presentingViewController != nil) {
		[self.presentingViewController presentViewController:alertController animated:YES completion:nil];
	} else {
		[alertController apptentive_presentAnimated:YES completion:nil];
	}
}

- (BOOL)shouldOpenAppStoreViaStoreKit {
	return ([SKStoreProductViewController class] != NULL && [self appID]);
}

- (NSURL *)URLForRatingApp {
	NSString *urlString = self.interaction.configuration[@"url"];

	NSURL *ratingURL = (urlString) ? [NSURL URLWithString:urlString] : [self legacyURLForRatingApp];

	return ratingURL;
}

- (NSURL *)legacyURLForRatingApp {
	NSString *URLString = nil;

	URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@?action=write-review", [self appID]];

	return [NSURL URLWithString:URLString];
}

- (void)openAppStoreViaURL {
	if ([self appID]) {
		NSURL *url = [self URLForRatingApp];

		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[Apptentive.shared.backend engage:ATInteractionAppStoreRatingEventLabelOpenAppStoreURL fromInteraction:self.interaction fromViewController:self.presentingViewController];

			[ApptentiveURLOpener openURL:url completionHandler:^(BOOL success) {
				if (!success) {
					ApptentiveLogWarning(ApptentiveLogTagInteractions, @"Could not open App Store URL: %@", url);
				}
			}];
		} else {
			ApptentiveLogWarning(ApptentiveLogTagInteractions, @"No application can open the Interaction's URL (%@), or the %@ scheme is missing from Info.plist's LSApplicationQueriesSchemes value.", url, url.scheme);
			[self showUnableToOpenAppStoreDialog];
		}
	} else {
		ApptentiveLogError(ApptentiveLogTagInteractions, @"Could not open App Store because App ID is not set. Set the `appID` property locally, or configure it remotely via the Apptentive dashboard.");

		[self showUnableToOpenAppStoreDialog];
	}
}

- (void)openAppStoreViaStoreKit {
	if ([SKStoreProductViewController class] != NULL && [self appID]) {
		ApptentiveStoreProductViewController *vc = [[ApptentiveStoreProductViewController alloc] init];
		vc.delegate = self;
		[vc loadProductWithParameters:@{ SKStoreProductParameterITunesItemIdentifier: self.appID }
					  completionBlock:^(BOOL result, NSError *error) {
						if (error) {
							ApptentiveLogWarning(ApptentiveLogTagInteractions, @"Unable to load product view (%@).", error);
							[self showUnableToOpenAppStoreDialog];
						} else {
							[Apptentive.shared.backend engage:ATInteractionAppStoreRatingEventLabelOpenStoreKit fromInteraction:self.interaction fromViewController:self.presentingViewController];

							UIViewController *presentingVC = self.presentingViewController;

							if (presentingVC != nil) {
								[presentingVC presentViewController:vc animated:YES completion:nil];
							} else {
								[vc presentAnimated:YES completion:nil];
							}
						}
					  }];
	} else {
		[self showUnableToOpenAppStoreDialog];
	}
}

#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)productViewController {
	[productViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)openMacAppStore {
	[Apptentive.shared.backend engage:ATInteractionAppStoreRatingEventLabelOpenMacAppStore fromInteraction:self.interaction fromViewController:self.presentingViewController];
}

@end

NS_ASSUME_NONNULL_END
