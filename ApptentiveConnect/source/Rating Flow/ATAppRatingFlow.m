//
//  ATAppRatingFlow.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAppRatingFlow.h"
#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATAppConfigurationUpdater.h"
#import "ATAutomatedMessage.h"
#import "ATFeedback.h"
#import "ATMessageSender.h"
#import "ATReachability.h"
#import "ATUtilities.h"
#import "ATWebClient.h"

// Set when the ratings module is loaded.
static CFAbsoluteTime ratingsLoadTime = 0.0;

// Don't count an app re-launch within 20 seconds as
// an app launch.
#define kATAppAppUsageMinimumInterval (20)

#if TARGET_OS_IPHONE
@interface ATAppRatingFlow ()
@property (nonatomic, retain) UIViewController *viewController;
@end
#endif


@interface ATAppRatingFlow (Private)
- (void)postNotification:(NSString *)name;
- (void)postNotification:(NSString *)name forButton:(int)button;
- (NSURL *)URLForRatingApp;
- (void)userAgreedToRateApp;
- (void)openAppStoreToRateApp;
- (BOOL)shouldOpenAppStoreViaStoreKit;
- (void)openAppStoreViaURL;
- (void)openAppStoreViaStoreKit;
- (void)openMacAppStore;
- (BOOL)requirementsToShowDialogMet;
- (BOOL)shouldShowDialog;

#if TARGET_OS_IPHONE
- (void)appDidFinishLaunching:(NSNotification *)notification;
- (void)appDidEnterBackground:(NSNotification *)notification;
- (void)appWillEnterForeground:(NSNotification *)notification;
- (void)appWillResignActive:(NSNotification *)notification;

#endif
- (void)tryToShowDialogWaitingForReachability;
- (void)reachabilityChangedAndPendingDialog:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)loadPreferences;
@end


@implementation ATAppRatingFlow
#if TARGET_OS_IPHONE
@synthesize viewController;
#endif

+ (void)load {
	// Set the first time this app was used.
	ratingsLoadTime = CFAbsoluteTimeGetCurrent();
}

- (id)init {
	if ((self = [super init])) {
		[self loadPreferences];
#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
#endif
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:ATConfigurationPreferencesChangedNotification object:nil];
	}
	return self;
}

- (void)dealloc {
#if	TARGET_OS_IPHONE
	self.viewController = nil;
#endif
	[super dealloc];
}

- (void)openAppStore {
	[self openAppStoreToRateApp];
}

#pragma mark Properties

#if TARGET_OS_IPHONE


#pragma mark SKStoreProductViewControllerDelegate
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)productViewController {
	[productViewController dismissViewControllerAnimated:YES completion:NULL];
}
#endif
@end


@implementation ATAppRatingFlow (Private)

- (void)postNotification:(NSString *)name {
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (void)postNotification:(NSString *)name forButton:(int)button {

}

- (NSURL *)URLForRatingApp {
	NSString *URLString = nil;
	NSString *URLStringFromPreferences = nil;
	if (URLStringFromPreferences == nil) {
#if TARGET_OS_IPHONE
		if ([ATUtilities osVersionGreaterThanOrEqualTo:@"6.0"]) {
			URLString = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/%@/app/id%@", [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode], [ATConnect sharedConnection].appID];
		} else {
			URLString = [NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [ATConnect sharedConnection].appID];
		}
#elif TARGET_OS_MAC
		URLString = [NSString stringWithFormat:@"macappstore://itunes.apple.com/app/id%@?mt=12", self.appID];
#endif
	} else {
		URLString = URLStringFromPreferences;
	}
	return [NSURL URLWithString:URLString];
}

#if TARGET_OS_IPHONE
- (void)showUnableToOpenAppStoreDialog {
	UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Oops!", @"Unable to load the App Store title") message:ATLocalizedString(@"Unable to load the App Store", @"Unable to load the App Store message") delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil] autorelease];
	[errorAlert show];
}
#endif

- (void)userAgreedToRateApp {
	[self openAppStoreToRateApp];
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

- (BOOL)shouldOpenAppStoreViaStoreKit {
	return ([SKStoreProductViewController class] != NULL && [ATConnect sharedConnection].appID && ![ATUtilities osVersionGreaterThanOrEqualTo:@"7"]);
}

- (void)openAppStoreViaURL {
	if ([ATConnect sharedConnection].appID) {
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
	if ([SKStoreProductViewController class] != NULL && [ATConnect sharedConnection].appID) {
		SKStoreProductViewController *vc = [[[SKStoreProductViewController alloc] init] autorelease];
		vc.delegate = self;
		[vc loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier:[ATConnect sharedConnection].appID} completionBlock:^(BOOL result, NSError *error) {
			if (error) {
				ATLogError(@"Error loading product view: %@", error);
				[self showUnableToOpenAppStoreDialog];
			} else {
				UIViewController *presentingVC = [ATUtilities rootViewControllerForCurrentWindow];
				[presentingVC presentViewController:vc animated:YES completion:^{}];
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

- (BOOL)requirementsToShowDialogMet {
	BOOL result = NO;
	NSString *reasonForNotShowingDialog = nil;
	
	do { // once
		
		// Legacy Rating Flow is disabled in favor of the Engagement Framework ratings flow
		BOOL disableLegacyRatingFlow = YES;
		if (disableLegacyRatingFlow) {
			reasonForNotShowingDialog = @"legacy rating flow is disabled. Please use Events and the Rating Flow Interaction instead.";
			break;
		}
		
	} while (NO);
	
	if (reasonForNotShowingDialog) {
		ATLogInfo(@"Did not show Apptentive ratings dialog because %@", reasonForNotShowingDialog);
	}
	
	return result;
}

- (BOOL)shouldShowDialog {
	// No network connection, don't show dialog.
	if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
		ATLogInfo(@"shouldShowDialog failed because network not reachable");
		return NO;
	}
	return [self requirementsToShowDialogMet];
}

#if TARGET_OS_IPHONE
- (void)appDidFinishLaunching:(NSNotification *)notification {

}

- (void)appDidEnterBackground:(NSNotification *)notification {

}

- (void)appWillEnterForeground:(NSNotification *)notification {

}

- (void)appWillResignActive:(NSNotification *)notification {

}

- (void)appWillEnterBackground:(NSNotification *)notification {
	// We want to hide any dialogs here.
}

#endif

- (void)tryToShowDialogWaitingForReachability {
	if (![[NSThread currentThread] isMainThread]) {
		[self performSelectorOnMainThread:@selector(tryToShowDialogWaitingForReachability) withObject:nil waitUntilDone:NO];
		return;
	}
	@autoreleasepool {
#if TARGET_OS_IPHONE
		UIViewController *vc = [ATUtilities rootViewControllerForCurrentWindow];
		
		if (vc && [self requirementsToShowDialogMet]) {
			// We can get a root view controller and we should be showing a dialog.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
		}
#elif TARGET_OS_MAC
		if ([self requirementsToShowDialogMet]) {
			// We should show a ratings dialog.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
		}
#endif
	}
}

- (void)reachabilityChangedAndPendingDialog:(NSNotification *)notification {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ATReachabilityStatusChanged object:nil];

#if TARGET_OS_IPHONE
		UIViewController *vc = [ATUtilities rootViewControllerForCurrentWindow];
		
		if (vc && [self requirementsToShowDialogMet]) {
			if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
			} else {

			}
			
		}
#elif TARGET_OS_MAC
		if ([self requirementsToShowDialogMet]) {
			if ([[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable) {
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChangedAndPendingDialog:) name:ATReachabilityStatusChanged object:nil];
			} else {
				[self showEnjoymentDialog:self];
			}
		}
#endif
	}
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self loadPreferences];
}

- (void)loadPreferences {

}
@end
