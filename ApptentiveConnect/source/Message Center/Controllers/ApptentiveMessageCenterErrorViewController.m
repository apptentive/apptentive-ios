//
//  ApptentiveMessageCenterErrorViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 8/4/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterErrorViewController.h"
#import "ApptentiveReachability.h"
#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveEngagementBackend.h"

NSString *const ATInteractionMessageCenterErrorViewInteractionKey = @"MessageCenter";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionNoInternet = @"no_interaction_no_internet";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionAttempting = @"no_interaction_attempting";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionClose = @"no_interaction_close";


@interface ApptentiveMessageCenterErrorViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;

@end


@implementation ApptentiveMessageCenterErrorViewController

- (NSString *)codePointForEvent:(NSString *)event {
	return [ApptentiveEngagementBackend codePointForVendor:ATEngagementCodePointApptentiveVendorKey interactionType:ATInteractionMessageCenterErrorViewInteractionKey event:event];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.title = ApptentiveLocalizedString(@"Message Center", @"Message Center default title");

	if ([ApptentiveReachability sharedReachability].currentNetworkStatus == ApptentiveNetworkNotReachable) {
		self.imageView.image = [[ApptentiveBackend imageNamed:@"at_network_error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"You must connect to the internet before you can send feedback.", @"Message Center configuration hasn't downloaded due to connection problem.");

		[[Apptentive sharedConnection].engagementBackend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionNoInternet] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	} else {
		self.imageView.image = [[ApptentiveBackend imageNamed:@"at_error_wait"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"We’re attempting to connect. Thanks for your patience!", @"Message Center configuration is waiting to be downloaded or encountered a server error.");

		[[Apptentive sharedConnection].engagementBackend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionAttempting] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	}

	self.imageView.tintColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.textLabel.textColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.view.backgroundColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveColorCollectionBackground];

	[[NSNotificationCenter defaultCenter] addObserverForName:ApptentiveInteractionsShouldDismissNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
		BOOL animated = [note.userInfo[ApptentiveInteractionsShouldDismissAnimatedKey] boolValue];
		[self dismissViewControllerAnimated:animated completion:^{
			[[Apptentive sharedConnection].engagementBackend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionClose] fromInteraction:nil userInfo:@{ @"cause": @"notification" } customData:nil extendedData:nil fromViewController:self];
		}];
	}];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)dismiss:(id)sender {
	[[Apptentive sharedConnection].engagementBackend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionClose] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];

	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
