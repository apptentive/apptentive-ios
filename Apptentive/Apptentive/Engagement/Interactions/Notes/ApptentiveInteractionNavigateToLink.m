//
//  ApptentiveInteractionNavigateToLink.m
//  Apptentive
//
//  Created by Peter Kamb on 12/19/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionNavigateToLink.h"
#import "ApptentiveInteraction.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveURLOpener.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionNavigateToLinkEventLabelNavigate = @"navigate";


@implementation ApptentiveInteractionNavigateToLink

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"NavigateToLink"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	NSString *urlString = self.interaction.configuration[@"url"];
	NSURL *url = [NSURL URLWithString:urlString];

	void (^engageBlock)(BOOL) = ^void(BOOL success) {
		NSDictionary *userInfo = @{ @"url": (urlString ?: [NSNull null]), @"success": @(success) };

		[Apptentive.shared.backend engage:ATInteractionNavigateToLinkEventLabelNavigate fromInteraction:self.interaction fromViewController:nil userInfo:userInfo];
	};

	if (!url) {
		ApptentiveLogError(ApptentiveLogTagInteractions, @"No URL was included in the NavigateToLink Interaction's configuration.");
		engageBlock(NO);
	} else if (![[UIApplication sharedApplication] canOpenURL:url]) {
		ApptentiveLogWarning(ApptentiveLogTagInteractions, @"No application can open the Interaction's URL (%@), or the %@ scheme is missing from Info.plist's LSApplicationQueriesSchemes value.", url, url.scheme);
		engageBlock(NO);
	} else {
		[ApptentiveURLOpener openURL:url completionHandler:^(BOOL success) {
			if (!success) {
				ApptentiveLogWarning(ApptentiveLogTagInteractions, @"Could not open URL %@.", url);
			}

			engageBlock(success);
		}];
	}
}

@end

NS_ASSUME_NONNULL_END
