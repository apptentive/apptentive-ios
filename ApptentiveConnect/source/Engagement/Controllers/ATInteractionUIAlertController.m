//
//  ATInteractionUIAlertController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertController.h"
#import "ATEngagementBackend.h"

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
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *actionTitle = action[@"label"];
		
		NSString *actionStyle = action[@"style"];
		UIAlertActionStyle alertActionStyle;
		if ([actionStyle isEqualToString:@"default"]) {
			alertActionStyle = UIAlertActionStyleDefault;
		} else if ([actionStyle isEqualToString:@"cancel"]) {
			alertActionStyle = UIAlertActionStyleCancel;
		} else if ([actionStyle isEqualToString:@"destructive"]) {
			alertActionStyle = UIAlertActionStyleDestructive;
		} else {
			alertActionStyle = UIAlertActionStyleDefault;
		}

		NSString *actionType = action[@"action"];
		alertActionHandler actionHandler;
		if ([actionType isEqualToString:@"dismiss"]) {
			actionHandler = [alertController createButtonHandlerBlockDismiss];
		} else if ([actionType isEqualToString:@"interaction"]) {
			actionHandler = [alertController createButtonHandlerBlockInvokeInteraction];
		} else {
			actionHandler = [alertController createButtonHandlerBlockDismiss];
		}
		
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle style:alertActionStyle handler:actionHandler];
		
		Block_release(actionHandler);
		
		BOOL enabled = action[@"enabled"] ? [action[@"enabled"] boolValue] : YES;
		alertAction.enabled = enabled;
		
		[alertController addAction:alertAction];
		
	}
	
	return alertController;
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
