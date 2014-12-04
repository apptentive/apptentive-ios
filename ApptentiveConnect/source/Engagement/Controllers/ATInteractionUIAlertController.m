//
//  ATInteractionUIAlertController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertController.h"

@interface ATInteractionUIAlertController ()

@end

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
			NSURL *url = [NSURL URLWithString:@"TODO"];
			actionHandler = [self createButtonHandlerBlockDeepLink:url];
		} else if ([actionType isEqualToString:@"engageEvent"]) {
			NSString *event = @"TODO";
			actionHandler = [self createButtonHandlerBlockEngage:event];
		} else if ([actionType isEqualToString:@"dismiss"]) {
			actionHandler = [self createButtonHandlerBlockDismiss];
		} else {
			actionHandler = [self createButtonHandlerBlockDismiss];
		}
		
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle style:alertActionStyle handler:actionHandler];
		
		Block_release(actionHandler);
		
		BOOL enabled = action[@"enabled"] ? [action[@"enabled"] boolValue] : YES;
		alertAction.enabled = enabled;
		
		[alertController addAction:alertAction];
		
	}
	
	return alertController;
}

+ (alertActionHandler)createButtonHandlerBlockDismiss {
	return Block_copy(^(UIAlertAction *action) {
		ATLogInfo(@"Tapped `Dismiss` button!");
	});
}

+ (alertActionHandler)createButtonHandlerBlockEngage:(NSString *)event {
	return Block_copy(^(UIAlertAction *action) {
		ATLogInfo(@"Tapped `Engage Event` button with event: `%@`", event);
	});
}

+ (alertActionHandler)createButtonHandlerBlockDeepLink:(NSURL *)url {
	return Block_copy(^(UIAlertAction *action) {
		ATLogInfo(@"Tapped `Deep Link` button with URL: `%@`", url);
	});
}

@end
