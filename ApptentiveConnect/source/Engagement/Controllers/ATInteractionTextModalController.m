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
@end
