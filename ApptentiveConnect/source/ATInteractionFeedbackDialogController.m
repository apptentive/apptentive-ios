//
//  ATInteractionFeedbackDialogController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 3/3/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionFeedbackDialogController.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATAppRatingMetrics.h"

@implementation ATInteractionFeedbackDialogController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"FeedbackDialog"], @"Attempted to load a FeedbackDialogController with an interaction of type: %@", interaction.type);
	self = [super init];
	if (self != nil) {
		_interaction = [interaction copy];
	}
	return self;
}

- (void)showFeedbackDialogFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;
		
	if (!self.viewController) {
		ATLogError(@"No view controller to present feedback interface!!");
	} else {
		NSDictionary *config = self.interaction.configuration;
		NSString *title = config[@"TODO_MESSAGE_TITLE"] ?: ATLocalizedString(@"We're Sorry!", @"We're sorry text");
		NSString *body = config[@"TODO_MESSAGE_BODY"] ?: ATLocalizedString(@"What can we do to ensure that you love our app? We appreciate your constructive feedback.", @"Custom placeholder feedback text when user is unhappy with the application.");
		[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
		
		[[ATBackend sharedBackend] presentIntroDialogFromViewController:self.viewController withTitle:title prompt:body placeholderText:nil];
	}
}

@end
