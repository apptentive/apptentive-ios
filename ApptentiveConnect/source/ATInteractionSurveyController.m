//
//  ATInteractionSurveyController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 4/9/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionSurveyController.h"

#import "ATInteraction.h"
#import "ATBackend.h"

@implementation ATInteractionSurveyController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"Survey"], @"Attempted to load a SurveyController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showSurveyFromViewController:(UIViewController *)viewController {
	[self retain];
	
	self.viewController = viewController;
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
