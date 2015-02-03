//
//  ATInteractionTextModalController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionTextModalController.h"
#import "ATUtilities.h"
#import "ATInteractionInvocation.h"
#import "ATEngagementBackend.h"

NSString *const ATInteractionTextModalEventLabelLaunch = @"launch";
NSString *const ATInteractionTextModalEventLabelCancel = @"cancel";
NSString *const ATInteractionTextModalEventLabelDismiss = @"dismiss";
NSString *const ATInteractionTextModalEventLabelInteraction = @"interaction";

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
		
		if (self.alertController) {
			[viewController presentViewController:self.alertController animated:YES completion:^{
				[self.interaction engage:ATInteractionTextModalEventLabelLaunch fromViewController:self.viewController];
			}];
		}
	}
	else {
		self.alertView = [self alertViewWithInteraction:self.interaction];
		
		if (self.alertView) {
			[self.alertView show];
		}
	}
}

#pragma mark UIAlertView

- (UIAlertView *)alertViewWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Skipping display of Apptentive Note that does not have a title and body.");
		return nil;
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *title = action[@"label"];
		
		// Better to use default button text than to potentially create an un-cancelable alert with no buttons.
		// 'UIAlertView: Buttons added must have a title.'
		if(!title) {
			ATLogError(@"Apptentive Note button action does not have a title!");
			title = @"button";
		}
	
		[alertView addButtonWithTitle:title];
	}
	
	return [alertView autorelease];
}

#pragma mark UIAlertController

- (UIAlertController *)alertControllerWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Skipping display of Apptentive Note that does not have a title and body.");
		return nil;
	}
	
	NSString *layout = config[@"layout"];
	UIAlertControllerStyle preferredStyle;
	if ([layout isEqualToString:@"center"]) {
		preferredStyle = UIAlertControllerStyleAlert;
	} else if ([layout isEqualToString:@"bottom"]) {
		preferredStyle = UIAlertControllerStyleActionSheet;
	} else {
		preferredStyle = UIAlertControllerStyleAlert;
	}
	
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
	
	BOOL cancelActionAdded = NO;
	NSArray *actions = config[@"actions"];
	
	for (int i = 0; i < actions.count; i++) {
		NSDictionary *actionForButton = actions[i];
		
		// Action position saved here and sent when button is tapped.
		NSMutableDictionary *actionConfig = [NSMutableDictionary dictionary];
		actionConfig[@"position"] = @(i);
		[actionConfig addEntriesFromDictionary:actionForButton];
		
		UIAlertAction *alertAction = [self alertActionWithConfiguration:actionConfig];
		
		// Adding more than one cancel action to the alert causes crash.
		// 'NSInternalInconsistencyException', reason: 'UIAlertController can only have one action with a style of UIAlertActionStyleCancel'
		if (alertAction.style == UIAlertActionStyleCancel) {
			if (!cancelActionAdded) {
				cancelActionAdded = YES;
			} else {
				// Additional cancel buttons are ignored.
				ATLogError(@"Apptentive Notes cannot have more than one cancel button.");
				continue;
			}
		}
		
		if (alertAction) {
			[alertController addAction:alertAction];
		}
	}
	
	return alertController;
}

#pragma mark Alert Button Actions

- (UIAlertAction *)alertActionWithConfiguration:(NSDictionary *)actionConfig {
	NSString *title = actionConfig[@"label"];
	
	// Better to use default button text than to potentially create an un-cancelable alert with no buttons.
	// Exception: 'Actions added to UIAlertController must have a title'
	if (!title) {
		ATLogError(@"Apptentive Note button action does not have a title!");
		title = @"button";
	}
	
	UIAlertActionStyle style = UIAlertActionStyleDefault;
	// Future support for configuration of different UIAlertActionStyles
	/*
	NSString *styleString = actionConfig[@"style"];
	UIAlertActionStyle style;
	if ([styleString isEqualToString:@"default"]) {
		style = UIAlertActionStyleDefault;
	} else if ([styleString isEqualToString:@"cancel"]) {
		style = UIAlertActionStyleCancel;
	} else if ([styleString isEqualToString:@"destructive"]) {
		style = UIAlertActionStyleDestructive;
	} else {
		style = UIAlertActionStyleDefault;
	}
	*/
	
	NSString *actionType = actionConfig[@"action"];
	alertActionHandler actionHandler = nil;
	if ([actionType isEqualToString:@"dismiss"]) {
		actionHandler = [self createButtonHandlerBlockDismiss:actionConfig];
	} else if ([actionType isEqualToString:@"interaction"]) {
		actionHandler = [self createButtonHandlerBlockInteractionAction:actionConfig];
	} else {
		ATLogError(@"Apptentive note contains an unknown action.");
	}
	
	UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:actionHandler];
	Block_release(actionHandler);
	
	// Future support for configuration of enabled/disabled actions
	/*
	BOOL enabled = actionConfig[@"enabled"] ? [actionConfig[@"enabled"] boolValue] : YES;
	alertAction.enabled = enabled;
	*/
	
	return alertAction;
}

- (void)dismissAction:(NSDictionary *)actionConfig {
	NSDictionary *userInfo = @{@"label": (actionConfig[@"label"] ?: [NSNull null]),
							   @"position": (actionConfig[@"position"] ?: [NSNull null]),
							   @"action_id": (actionConfig[@"id"] ?: [NSNull null]),
							   };
	
	[self.interaction engage:ATInteractionTextModalEventLabelDismiss fromViewController:self.viewController userInfo:userInfo];
}

- (alertActionHandler)createButtonHandlerBlockDismiss:(NSDictionary *)actionConfig {
	return Block_copy(^(UIAlertAction *alertAction) {
		[self dismissAction:actionConfig];
	});
}

- (void)interactionAction:(NSDictionary *)actionConfig {
	ATInteraction *interaction = nil;
	NSArray *invocations = actionConfig[@"invokes"];
	if (invocations) {
		interaction = [[ATEngagementBackend sharedBackend] interactionForInvocations:invocations];
	}
	
	NSDictionary *userInfo = @{@"label": (actionConfig[@"label"] ?: [NSNull null]),
							   @"position": (actionConfig[@"position"] ?: [NSNull null]),
							   @"invoked_interaction_id": (interaction.identifier ?: [NSNull null]),
							   @"action_id": (actionConfig[@"id"] ?: [NSNull null]),
							   };
	
	[self.interaction engage:ATInteractionTextModalEventLabelInteraction fromViewController:self.viewController userInfo:userInfo];
	
	if (interaction) {
		[[ATEngagementBackend sharedBackend] presentInteraction:interaction fromViewController:self.viewController];
	}
}

- (alertActionHandler)createButtonHandlerBlockInteractionAction:(NSDictionary *)actionConfig {
	return Block_copy(^(UIAlertAction *alertAction) {
		[self interactionAction:actionConfig];
	});
}

#pragma mark UIAlertViewDelegate

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[self.interaction engage:ATInteractionTextModalEventLabelLaunch fromViewController:self.viewController];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSArray *actions = self.interaction.configuration[@"actions"];
	NSDictionary *actionForButton = [actions objectAtIndex:buttonIndex];
	
	if (actionForButton) {
		NSMutableDictionary *actionConfig = [NSMutableDictionary dictionary];
		actionConfig[@"position"] = @(buttonIndex);
		[actionConfig addEntriesFromDictionary:actionForButton];
		
		NSString *actionTitle = actionConfig[@"label"];
		NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
		
		if (![actionTitle isEqualToString:buttonTitle]) {
			ATLogError(@"Cannot find an action for the tapped UIAlertView button.");
		} else {
			NSString *actionType = actionConfig[@"action"];
			if ([actionType isEqualToString:@"dismiss"]) {
				[self dismissAction:actionConfig];
			} else if ([actionType isEqualToString:@"interaction"]) {
				[self interactionAction:actionConfig];
			} else {
				ATLogError(@"Apptentive note contains an unknown action.");
			}
		}
	}
	
	[self release];
}

- (void)dealloc {
	[_interaction release], _interaction = nil;
	[_alertController release], _alertController = nil;
	_alertView.delegate = nil;
	[_alertView release], _alertView = nil;
	[_viewController release], _viewController = nil;
	
	[super dealloc];
}

@end
