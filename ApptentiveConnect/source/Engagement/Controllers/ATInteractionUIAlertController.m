//
//  ATInteractionUIAlertController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertController.h"
#import "ATEngagementBackend.h"
#import "ATInteractionInvocation.h"

NSString *const ATInteractionUIAlertControllerEventLabelDismiss = @"dismiss";

@implementation ATInteractionUIAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentAlertControllerFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;
	
	[viewController presentViewController:self animated:YES completion:nil];
}

+ (instancetype)alertControllerWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	NSString *layout = config[@"layout"];
	UIAlertControllerStyle preferredStyle;
	if ([layout isEqualToString:@"center"]) {
		preferredStyle = UIAlertControllerStyleAlert;
	} else if ([layout isEqualToString:@"bottom"]) {
		preferredStyle = UIAlertControllerStyleActionSheet;
	} else {
		preferredStyle = UIAlertControllerStyleAlert;
	}
	
	ATInteractionUIAlertController *alertController = [super alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
	alertController.interaction = interaction;
	
	BOOL cancelActionAdded = NO;
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		UIAlertAction *alertAction = [alertController alertActionWithConfiguration:action];
		
		// Do not add more than 1 cancel action to the alert
		// 'NSInternalInconsistencyException', reason: 'UIAlertController can only have one action with a style of UIAlertActionStyleCancel'
		if (alertAction.style == UIAlertActionStyleCancel) {
			if (!cancelActionAdded) {
				cancelActionAdded = YES;
			} else {
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

- (alertActionHandler)createButtonHandlerBlockDismiss {
	return Block_copy(^(UIAlertAction *action) {
		[[ATEngagementBackend sharedBackend] engageApptentiveEvent:ATInteractionUIAlertControllerEventLabelDismiss fromInteraction:self.interaction fromViewController:self.viewController];
	});
}

- (alertActionHandler)createButtonHandlerBlockWithInvocations:(NSArray *)invocations {
	return Block_copy(^(UIAlertAction *action) {
		ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForInvocations:invocations];
		[[ATEngagementBackend sharedBackend] presentInteraction:interaction fromViewController:self.viewController];
	});
}

@end
