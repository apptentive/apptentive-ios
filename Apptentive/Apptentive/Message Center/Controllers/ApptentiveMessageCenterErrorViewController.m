//
//  ApptentiveMessageCenterErrorViewController.m
//  Apptentive
//
//  Created by Frank Schmitt on 8/4/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterErrorViewController.h"
#import "ApptentiveReachability.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN

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
	return [ApptentiveBackend codePointForVendor:ATEngagementCodePointApptentiveVendorKey interactionType:ATInteractionMessageCenterErrorViewInteractionKey event:event];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.navigationItem.title = ApptentiveLocalizedString(@"Message Center", @"Message Center default title");

	if (!Apptentive.shared.backend.networkAvailable) {
		self.imageView.image = [[ApptentiveUtilities imageNamed:@"at_network_error"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"You must connect to the internet before you can send feedback.", @"Message Center configuration hasn't downloaded due to connection problem.");

		[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionNoInternet] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
	} else {
		self.imageView.image = [[ApptentiveUtilities imageNamed:@"at_error_wait"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		self.textLabel.text = ApptentiveLocalizedString(@"We’re attempting to connect. Thanks for your patience!", @"Message Center configuration is waiting to be downloaded or encountered a server error.");

		[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionAttempting] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
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
	[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionClose] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];

	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissNotification:(NSNotification *)notification {
	BOOL animated = [notification.userInfo[ApptentiveInteractionsShouldDismissAnimatedKey] boolValue];
	[self dismissViewControllerAnimated:animated completion:nil];

	[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionMessageCenterEventLabelNoInteractionClose] fromInteraction:nil userInfo:@{ @"cause": @"notification" } customData:nil extendedData:nil fromViewController:self];
}

@end

NS_ASSUME_NONNULL_END
