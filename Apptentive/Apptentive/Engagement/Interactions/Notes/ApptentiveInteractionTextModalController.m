//
//  ApptentiveInteractionTextModalController.m
//  Apptentive
//
//  Created by Peter Kamb on 1/27/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionTextModalController.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionInvocation.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "UIAlertController+Apptentive.h"

NS_ASSUME_NONNULL_BEGIN


NSString *const ATInteractionTextModalEventLabelLaunch = @"launch";
NSString *const ATInteractionTextModalEventLabelCancel = @"cancel";
NSString *const ATInteractionTextModalEventLabelDismiss = @"dismiss";

typedef void (^alertActionHandler)(UIAlertAction *);


@implementation ApptentiveInteractionTextModalController

+ (void)load {
	[self registerInteractionControllerClass:self forType:@"TextModal"];
}

- (void)presentInteractionFromViewController:(nullable UIViewController *)viewController {
	[super presentInteractionFromViewController:viewController];

	self.presentedViewController = [self alertControllerWithInteraction:self.interaction];

	if (self.presentedViewController) {
		if (viewController != nil) {
			[viewController presentViewController:self.presentedViewController
										 animated:YES
									   completion:^{
										 [Apptentive.shared.backend engage:ATInteractionTextModalEventLabelLaunch fromInteraction:self.interaction fromViewController:viewController];
									   }];
		} else {
			[(UIAlertController *)self.presentedViewController apptentive_presentAnimated:YES
																			   completion:^{
																				 [Apptentive.shared.backend engage:ATInteractionTextModalEventLabelLaunch fromInteraction:self.interaction fromViewController:nil];
																			   }];
		}
	}
}

#pragma mark UIAlertController

- (nullable UIAlertController *)alertControllerWithInteraction:(ApptentiveInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];

	if (!title && !message) {
		ApptentiveLogError(@"Skipping display of Apptentive Note that does not have a title and body.");
		return nil;
	}

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

	BOOL cancelActionAdded = NO;
	NSArray *actions = config[@"actions"];

	for (NSUInteger i = 0; i < actions.count; i++) {
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
				ApptentiveLogError(@"Apptentive Notes cannot have more than one cancel button.");
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
		ApptentiveLogError(@"Apptentive Note button action does not have a title!");
		title = ApptentiveLocalizedString(@"OK", @"OK");
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
		ApptentiveLogError(@"Apptentive note contains an unknown action.");
	}

	UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:actionHandler];

	// Future support for configuration of enabled/disabled actions
	/*
	BOOL enabled = actionConfig[@"enabled"] ? [actionConfig[@"enabled"] boolValue] : YES;
	alertAction.enabled = enabled;
	*/

	return alertAction;
}

- (void)dismissAction:(NSDictionary *)actionConfig {
	NSDictionary *userInfo = @{ @"label": (actionConfig[@"label"] ?: [NSNull null]),
		@"position": (actionConfig[@"position"] ?: [NSNull null]),
		@"action_id": (actionConfig[@"id"] ?: [NSNull null]),
	};

	[Apptentive.shared.backend engage:ATInteractionTextModalEventLabelDismiss fromInteraction:self.interaction fromViewController:self.presentingViewController userInfo:userInfo];

	self.presentedViewController = nil;
}

- (alertActionHandler)createButtonHandlerBlockDismiss:(NSDictionary *)actionConfig {
	return [^(UIAlertAction *alertAction) {
	  [self dismissAction:actionConfig];
	} copy];
}

- (void)interactionAction:(NSDictionary *)actionConfig {
	[Apptentive.shared.backend invokeAction:actionConfig withInteraction:self.interaction fromViewController:self.presentingViewController];

	self.presentedViewController = nil;
}

- (alertActionHandler)createButtonHandlerBlockInteractionAction:(NSDictionary *)actionConfig {
	return [^(UIAlertAction *alertAction) {
	  [self interactionAction:actionConfig];
	} copy];
}

@end

NS_ASSUME_NONNULL_END
