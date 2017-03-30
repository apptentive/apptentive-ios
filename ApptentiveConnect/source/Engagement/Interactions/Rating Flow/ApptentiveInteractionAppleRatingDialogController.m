//
//  ApptentiveInteractionAppleRatingDialogController.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/6/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionAppleRatingDialogController.h"
#import "ApptentiveInteraction.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveEngagementBackend.h"
#import <StoreKit/StoreKit.h>

NSString *const ApptentiveInteractionAppleRatingDialogEventLabelRequest = @"request";
NSString *const ApptentiveInteractionAppleRatingDialogEventLabelShown = @"shown";
NSString *const ApptentiveInteractionAppleRatingDialogEventLabelNotShown = @"not_shown";

#define REVIEW_WINDOW_TIMEOUT (int64_t)(1.0 * NSEC_PER_SEC)

@implementation ApptentiveInteractionAppleRatingDialogController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"AppleRatingDialog"];
}

- (void)presentInteractionFromViewController:(UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	[self.interaction engage:ApptentiveInteractionAppleRatingDialogEventLabelRequest fromViewController:viewController];
	NSString *notShownReason = nil;

	// Assume the review request will not be shown…
	__block BOOL didShowReviewController = NO;

	// …but listen for new windows whose class name starts with "SKStoreReview"
	id<NSObject> notifier = [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeVisibleNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
		if ([NSStringFromClass([note.object class]) hasPrefix:@"SKStoreReview"]) {
			// Review window was shown
			didShowReviewController = YES;
		}
	}];

	// Guard against not having store review controller class in OS and/or SDK
#ifdef __IPHONE_10_3
	if ([[SKStoreReviewController class] respondsToSelector:@selector(requestReview)]) {
		// This may or may not display a review window
		[SKStoreReviewController performSelector:@selector(requestReview)];
	} else {
		notShownReason = @"os too old";
	}
#else
	notShownReason = @"tools too old";
#endif

	// Give the window a sec to appear
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, REVIEW_WINDOW_TIMEOUT), dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] removeObserver:notifier];

		if (didShowReviewController) {
			[self.interaction engage:ApptentiveInteractionAppleRatingDialogEventLabelShown fromViewController:viewController];
		} else {
			[self invokeNotShownInteractionFromViewController:viewController withReason:notShownReason];
		}
	});
}

- (void)invokeNotShownInteractionFromViewController:(UIViewController *)viewController withReason:(NSString *)notShownReason {
	NSDictionary *userInfo = nil;

	if (notShownReason) {
		userInfo = @{ @"cause": notShownReason };
	}

	[self.interaction engage:ApptentiveInteractionAppleRatingDialogEventLabelNotShown fromViewController:viewController userInfo:userInfo];

	ApptentiveInteraction *interaction = [Apptentive.shared.engagementBackend interactionForIdentifier:self.interaction.configuration[@"not_shown_interaction"]];

	if (interaction) {
		[[Apptentive sharedConnection].engagementBackend presentInteraction:interaction fromViewController:viewController];
	}
}

@end
