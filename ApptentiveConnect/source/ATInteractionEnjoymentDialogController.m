//
//  ATInteractionEnjoymentDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/24/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionEnjoymentDialogController.h"

@implementation ATInteractionEnjoymentDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"EnjoymentDialog"], @"Attempted to load an EnjoymentDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_enjoymentDialogInteraction = interaction;
	}
	return self;
}

- (void)presentEnjoymentDialogFromViewController:(UIViewController *)viewController {
	
}

@end
