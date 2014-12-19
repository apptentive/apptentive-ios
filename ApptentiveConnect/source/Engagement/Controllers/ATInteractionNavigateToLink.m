//
//  ATInteractionNavigateToLink.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/19/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionNavigateToLink.h"

@implementation ATInteractionNavigateToLink

+ (void)navigateToLinkWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"NavigateToLink"], @"Attempted to load a NavigateToLink interaction with an interaction of type: %@", interaction.type);

	NSURL *url = [NSURL URLWithString:interaction.configuration[@"url"]];
	if (url) {
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
		} else {
			ATLogError(@"No application can open the Interaction's URL: %@", url);
		}
	} else {
		ATLogError(@"No URL was included in the NavigateToLink Interaction's configuration.");
	}
}

@end
