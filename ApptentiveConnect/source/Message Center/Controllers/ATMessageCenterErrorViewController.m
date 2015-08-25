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
#import "ATEngagementBackend.h"

NSString *const ATInteractionMessageCenterErrorViewInteractionKey = @"MessageCenter";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionNoInternet = @"no_interaction_no_internet";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionAttempting = @"no_interaction_attempting";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionClose = @"no_interaction_close";

@interface ATMessageCenterErrorViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation ATMessageCenterErrorViewController

- (NSString *)codePointForEvent:(NSString *)event {
	return [ATEngagementBackend codePointForVendor:ATEngagementCodePointApptentiveVendorKey interactionType:ATInteractionMessageCenterErrorViewInteractionKey event:event];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if ([[ATConnect sharedConnection] tintColor]) {
		[self.view setTintColor:[[ATConnect sharedConnection] tintColor]];
		self.navigationController.view.tintColor = [ATConnect sharedConnection].tintColor;
	}
	
	if ([ATReachability sharedReachability].currentNetworkStatus == ATNetworkNotReachable) {
		self.imageView.image = [ATBackend imageNamed:@"at_network_error"];
		self.textLabel.text = ATLocalizedString(@"You must connect to the internet before you can send feedback.", @"Message Center configuration hasn't downloaded due to connection problem.");
		
		[[ATEngagementBackend sharedBackend] engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionNoInternet] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	} else {
		self.imageView.image = [ATBackend imageNamed:@"at_error_wait"];
		self.textLabel.text = ATLocalizedString(@"We’re attempting to connect. Thanks for your patience!", @"Message Center configuration is waiting to be downloaded or encountered a server error.");
		
		[[ATEngagementBackend sharedBackend] engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionAttempting] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	}
}

- (IBAction)dismiss:(id)sender {
	[[ATEngagementBackend sharedBackend] engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionClose] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
