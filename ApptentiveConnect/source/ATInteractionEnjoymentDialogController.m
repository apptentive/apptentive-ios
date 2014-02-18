//
//  ATInteractionEnjoymentDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 2/18/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionEnjoymentDialogController.h"
#import "ATInteraction.h"

@implementation ATInteractionEnjoymentDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to load an EnjoymentDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_enjoymentDialogInteraction = interaction;
	}
	return self;
}

- (void)showRatingFlowFromViewController:(UIViewController *)viewController {
	
}

@end
