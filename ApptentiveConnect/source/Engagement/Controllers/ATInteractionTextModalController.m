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

- (UIAlertController *)alertControllerWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Cannot show an Apptentive alert without a title or message.");
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
	for (NSDictionary *action in actions) {
		UIAlertAction *alertAction = [self alertActionWithConfiguration:action];
		
		// Adding more than one cancel action to the alert causes crash.
		// 'NSInternalInconsistencyException', reason: 'UIAlertController can only have one action with a style of UIAlertActionStyleCancel'
		if (alertAction.style == UIAlertActionStyleCancel) {
			if (!cancelActionAdded) {
				cancelActionAdded = YES;
			} else {
				// Additional cancel buttons are ignored.
				break;
			}
		}
		
		[alertController addAction:alertAction];
	}
	
	return alertController;
}

- (UIAlertAction *)alertActionWithConfiguration:(NSDictionary *)configuration {
	NSString *title = configuration[@"label"] ?: @"button";
	
	NSString *styleString = configuration[@"style"];
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
	
	NSString *actionType = configuration[@"action"];
	alertActionHandler actionHandler;
	if ([actionType isEqualToString:@"dismiss"]) {
		actionHandler = [self createButtonHandlerBlockDismiss];
	} else if ([actionType isEqualToString:@"interaction"]) {
		NSArray *jsonInvocations = configuration[@"invokes"];
		NSArray *invocations = [ATInteractionInvocation invocationsWithJSONArray:jsonInvocations];
		actionHandler = [self createButtonHandlerBlockWithInvocations:invocations];
	} else {
		actionHandler = [self createButtonHandlerBlockDismiss];
	}
	
	UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:actionHandler];
	Block_release(actionHandler);
	
	BOOL enabled = configuration[@"enabled"] ? [configuration[@"enabled"] boolValue] : YES;
	alertAction.enabled = enabled;
	
	return alertAction;
}

- (void)dismissAction {
	[self.interaction engage:ATInteractionTextModalEventLabelDismiss fromViewController:self.viewController];
}

- (alertActionHandler)createButtonHandlerBlockDismiss {
	return Block_copy(^(UIAlertAction *action) {		
		[self dismissAction];
	});
}

- (void)interactionActionWithInvocations:(NSArray *)invocations {
	[self.interaction engage:ATInteractionTextModalEventLabelInteraction fromViewController:self.viewController];
	
	ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForInvocations:invocations];
	[[ATEngagementBackend sharedBackend] presentInteraction:interaction fromViewController:self.viewController];
}

- (alertActionHandler)createButtonHandlerBlockWithInvocations:(NSArray *)invocations {
	return Block_copy(^(UIAlertAction *action) {
		[self interactionActionWithInvocations:invocations];
	});
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
