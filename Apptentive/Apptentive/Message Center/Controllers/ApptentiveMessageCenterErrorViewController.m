//
//  ApptentiveMessageCenterErrorViewController.m
//  Apptentive
//
//  Created by Frank Schmitt on 8/4/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterErrorViewController.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveReachability.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveInteraction.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionMessageCenterErrorViewInteractionKey = @"MessageCenter";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionNoInternet = @"no_interaction_no_internet";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionAttempting = @"no_interaction_attempting";
NSString *const ATInteractionMessageCenterEventLabelNoInteractionClose = @"no_interaction_close";


@interface ApptentiveMessageCenterErrorViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;

@property (strong, nonatomic) ApptentiveInteraction *interaction;

@end


@implementation ApptentiveMessageCenterErrorViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.interaction = [[ApptentiveInteraction alloc] init];
	self.interaction.vendor = ATEngagementCodePointApptentiveVendorKey;
	self.interaction.type = ATInteractionMessageCenterErrorViewInteractionKey;

	self.navigationItem.title = ApptentiveLocalizedString(@"Message Center", @"Message Center default title");

	if (!Apptentive.shared.backend.networkAvailable) {
		self.imageView.image = [[ApptentiveUtilities imageNamed:@"at_network_error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"You must connect to the internet before you can send feedback.", @"Message Center configuration hasn't downloaded due to connection problem.");

		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelNoInteractionNoInternet fromInteraction:self.interaction fromViewController:self];
	} else {
		self.imageView.image = [[ApptentiveUtilities imageNamed:@"at_error_wait"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"We’re attempting to connect. Thanks for your patience!", @"Message Center configuration is waiting to be downloaded or encountered a server error.");

		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelNoInteractionAttempting fromInteraction:self.interaction fromViewController:self];
	}

	self.imageView.tintColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.textLabel.textColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.view.backgroundColor = [[Apptentive sharedConnection].style colorForStyle:ApptentiveColorCollectionBackground];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissNotification:) name:ApptentiveInteractionsShouldDismissNotification object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)dismiss:(id)sender {
	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelNoInteractionClose fromInteraction:self.interaction fromViewController:self];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissNotification:(NSNotification *)notification {
	BOOL animated = [notification.userInfo[ApptentiveInteractionsShouldDismissAnimatedKey] boolValue];
	[self dismissViewControllerAnimated:animated completion:nil];

	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelNoInteractionClose fromInteraction:self.interaction fromViewController:self userInfo:@{ @"cause": @"notification" }];
}

@end

NS_ASSUME_NONNULL_END
