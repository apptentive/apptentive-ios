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

typedef void (^alertActionHandler)(UIAlertAction *);

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
	NSString *message = config[@"message"];
	
	NSString *style = config[@"style"];
	UIAlertControllerStyle preferredStyle;
	if ([style isEqualToString:@"alert"]) {
		preferredStyle = UIAlertControllerStyleAlert;
	} else if ([style isEqualToString:@"actionSheet"]) {
		preferredStyle = UIAlertControllerStyleActionSheet;
	} else {
		preferredStyle = UIAlertControllerStyleAlert;
	}
	
	ATInteractionUIAlertController *alertController = [super alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
	alertController.interaction = interaction;
	
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		NSString *actionTitle = action[@"title"];
		
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

		NSString *actionType = action[@"type"];
		alertActionHandler actionHandler;
		if ([actionType isEqualToString:@"deepLink"]) {
			NSString *urlString = action[@"url"];
			NSURL *url = [NSURL URLWithString:urlString];
			actionHandler = [alertController createButtonHandlerBlockDeepLink:url];
		} else if ([actionType isEqualToString:@"engageEvent"]) {
			NSString *event = action[@"event"];
			actionHandler = [alertController createButtonHandlerBlockEngage:event];
		} else if ([actionType isEqualToString:@"dismiss"]) {
			actionHandler = [alertController createButtonHandlerBlockDismiss];
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

- (alertActionHandler)createButtonHandlerBlockEngage:(NSString *)event {
	return Block_copy(^(UIAlertAction *action) {
		[[ATEngagementBackend sharedBackend] engageApptentiveEvent:event fromInteraction:self.interaction fromViewController:self.viewController];
	});
}

- (alertActionHandler)createButtonHandlerBlockDeepLink:(NSURL *)url {
	return Block_copy(^(UIAlertAction *action) {
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
		} else {
			ATLogError(@"[ATInteractionUIAlertController] Unable to open URL: %@", url);
		}
	});
}

@end
