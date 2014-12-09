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

#warning REMOVE
+ (ATInteraction *)sampleMessagingInteraction {
	ATInteraction *interaction = [[[ATInteraction alloc] init] autorelease];
	interaction.type = @"TextModal";
	interaction.priority = 1;
	interaction.version = @"1.0.0";
	interaction.identifier = @"XYZ";
	interaction.criteria = @{};
	
	NSArray *actions = @[@{@"label": @"App Store",
						   @"style": @"default",
						   @"type": @"deepLink",
						   @"url": @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=471966214"
						   },
						 @{@"label": @"Survey",
						   @"style": @"default",
						   @"type": @"engageEvent",
						   @"enabled": @YES,
						   @"event": @"show_survey"
						   },
						 @{@"label": @"Disabled Button",
						   @"style": @"default",
						   @"type": @"dismiss",
						   @"enabled": @NO
						   },
						 @{@"label": @"Destructive Button",
						   @"style": @"destructive",
						   @"type": @"dismiss"
						   },
						 @{@"label": @"Cancel Button",
						   @"style": @"cancel",
						   @"type": @"dismiss"
						   }
						 ];
	
	NSDictionary *config = @{@"title": @"TITLE TITLE TITLE",
							 @"body": @"BODY TEXT BODY TEXT",
							 @"layout": @"center",
							 @"actions": actions
							 };
	
	interaction.configuration = config;

	return interaction;
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

- (alertActionHandler)createButtonHandlerBlockInvokeInteraction {
	return Block_copy(^(UIAlertAction *action) {
		//TODO
	});
}

@end
