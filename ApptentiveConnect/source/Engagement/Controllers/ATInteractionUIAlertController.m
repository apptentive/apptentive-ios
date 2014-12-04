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
	
	ATInteractionUIAlertController *alert = [super alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
	
	return alert;
}

@end
