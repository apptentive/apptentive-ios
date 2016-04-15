//
//  ApptentiveInteractionNavigateToLink.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/19/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionNavigateToLink.h"

NSString *const ATInteractionNavigateToLinkEventLabelNavigate = @"navigate";


@implementation ApptentiveInteractionNavigateToLink

+ (void)navigateToLinkWithInteraction:(ApptentiveInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"NavigateToLink"], @"Attempted to load a NavigateToLink interaction with an interaction of type: %@", interaction.type);

	BOOL openedURL = NO;
	NSString *urlString = interaction.configuration[@"url"];
	NSURL *url = [NSURL URLWithString:urlString];
	if (url) {
		BOOL attemptToOpenURL = [[UIApplication sharedApplication] canOpenURL:url];

		// In iOS 9, `canOpenURL:` returns NO unless that URL scheme has been added to LSApplicationQueriesSchemes.
		if (!attemptToOpenURL) {
			attemptToOpenURL = YES;
		}

		if (attemptToOpenURL) {
			openedURL = [[UIApplication sharedApplication] openURL:url];
			if (!openedURL) {
				ApptentiveLogError(@"Could not open URL: %@", url);
			}
		} else {
			ApptentiveLogError(@"No application can open the Interaction's URL: %@", url);
		}
	} else {
		ApptentiveLogError(@"No URL was included in the NavigateToLink Interaction's configuration.");
	}

	NSDictionary *userInfo = @{ @"url": (urlString ?: [NSNull null]),
		@"success": @(openedURL),
	};

	[interaction engage:ATInteractionNavigateToLinkEventLabelNavigate fromViewController:nil userInfo:userInfo];
}

@end
