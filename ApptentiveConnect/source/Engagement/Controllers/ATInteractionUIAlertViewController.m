//
//  ATInteractionUIAlertViewController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/26/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertViewController.h"

@implementation ATInteractionUIAlertViewController

- (void)presentAlertViewWithInteraction:(ATInteraction *)interaction {
	self.interaction = interaction;
	
	NSDictionary *config = self.interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Cannot show an Apptentive alert without a title or message.");
		return;
	}
	
	self.alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *title = action[@"label"];
		[self.alertView addButtonWithTitle:title];
	}
	
	[self.alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *actions = self.interaction.configuration[@"actions"];
	
	// TODO
}

@end
