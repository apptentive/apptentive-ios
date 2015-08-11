//
//  ATMessageCenterErrorViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 8/4/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterErrorViewController.h"
#import "ATReachability.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"

@interface ATMessageCenterErrorViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation ATMessageCenterErrorViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if ([ATReachability sharedReachability].currentNetworkStatus == ATNetworkNotReachable) {
		self.imageView.image = [ATBackend imageNamed:@"at_network_error"];
		self.textLabel.text = ATLocalizedString(@"You must connect to the internet before you can send feedback.", @"Message Center configuration hasn't downloaded due to connection problem.");
	} else {
		self.imageView.image = [ATBackend imageNamed:@"at_error_wait"];
		self.textLabel.text = ATLocalizedString(@"We’re attempting to connect. Thanks for your patience!", @"Message Center configuration is waiting to be downloaded or encountered a server error.");
	}
}

- (IBAction)dismiss:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
