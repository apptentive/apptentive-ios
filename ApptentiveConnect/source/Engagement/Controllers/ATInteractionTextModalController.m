//
//  ATInteractionTextModalController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionTextModalController.h"
#import "ATUtilities.h"

@implementation ATInteractionTextModalController

- (instancetype)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"TextModal"], @"Attempted to load a TextModalController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	
	return self;
}

- (void)presentTextModalAlertFromViewController:(UIViewController *)viewController {
	if (!self.interaction) {
		ATLogError(@"Cannot present a TextModal alert without an interaction.");
		return;
	}
	
	[self retain];
	self.viewController = viewController;
	
	if ([ATUtilities osVersionGreaterThanOrEqualTo:@"8.0"]) {
		self.alertController = [self alertControllerWithInteraction:self.interaction];
		
		[viewController presentViewController:self.alertController animated:YES completion:^{
			[self.interaction engage:ATInteractionTextModalEventLabelLaunch fromViewController:self.viewController];
		}];
	}
	else {
		self.alertView = [self alertViewWithInteraction:self.interaction];
		
		[self.alertView show];
	}
}

- (UIAlertView *)alertViewWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Cannot show an Apptentive alert without a title or message.");
		return nil;
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *title = action[@"label"];
		if (title) {
			[alertView addButtonWithTitle:title];
		}
	}
	
	return [alertView autorelease];
}
- (void)didPresentAlertView:(UIAlertView *)alertView {
	[self.interaction engage:ATInteractionTextModalEventLabelLaunch fromViewController:self.viewController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *actions = self.interaction.configuration[@"actions"];
	
	NSDictionary *action = [actions objectAtIndex:buttonIndex];
	if (action) {
		NSString *actionType = action[@"action"];
		if ([actionType isEqualToString:@"dismiss"]) {
			[self.interaction engage:ATInteractionTextModalEventLabelDismiss fromViewController:self.viewController];
			
			[self dismissAction];
			
		} else if ([actionType isEqualToString:@"interaction"]) {
			NSArray *jsonInvocations = action[@"invokes"];
			if (jsonInvocations) {
				[self interactionActionWithInvocations:jsonInvocations];
			}
		}
	}
	
	[self release];
}

@end
