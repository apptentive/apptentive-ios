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
		
		UIAlertAction *alertAction = [UIAlertAction actionWithTitle:actionTitle style:alertActionStyle handler:nil /*TODO install a handler*/];
		
		BOOL enabled = action[@"enabled"] ? [action[@"enabled"] boolValue] : YES;
		alertAction.enabled = enabled;
		
		[alertController addAction:alertAction];
		
	}
	
	return alertController;
}

@end
