//
//  ApptentiveAboutViewController.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/28/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAboutViewController.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveUtilities.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATInteractionAboutViewInteractionKey = @"About";
NSString *const ATInteractionAboutViewEventLabelLaunch = @"launch";
NSString *const ATInteractionAboutViewEventLabelClose = @"close";


@interface ApptentiveAboutViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;
@property (weak, nonatomic) IBOutlet UIButton *privacyButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboutButtonTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *privacyButtonLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboutButtonPrivacyButtonVeritcalConstraint;


@property (strong, nonatomic) NSArray *portraitConstraints;
@property (strong, nonatomic) NSArray *landscapeConstraints;

@end


@implementation ApptentiveAboutViewController

- (NSString *)codePointForEvent:(NSString *)event {
	return [ApptentiveBackend codePointForVendor:ATEngagementCodePointApptentiveVendorKey interactionType:ATInteractionAboutViewInteractionKey event:event];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionAboutViewEventLabelLaunch] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];

	self.imageView.image = [ApptentiveUtilities imageNamed:@"at_apptentive_logo"];
	// TODO: Look into localizing the storyboard instead
	self.aboutLabel.text = ApptentiveLocalizedString(@"Apptentive is a service that allows you to have a conversation with the makers of this app. Your input and feedback can help to provide you with a better overall experience.\n\nYour feedback is hosted by Apptentive and is subject to both Apptentive’s privacy policy and the privacy policy of this app’s developer.", @"About apptentive introductory message");
	[self.aboutButton setTitle:ApptentiveLocalizedString(@"Learn about Apptentive", @"About apptentive link button label") forState:UIControlStateNormal];
	[self.privacyButton setTitle:ApptentiveLocalizedString(@"Apptentive’s Privacy Policy", @"About apptentive privacy button label") forState:UIControlStateNormal];

	self.portraitConstraints = @[self.aboutButtonTrailingConstraint, self.privacyButtonLeadingConstraint, self.aboutButtonPrivacyButtonVeritcalConstraint];

	self.landscapeConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[about]-(16)-[privacy]" options:NSLayoutFormatAlignAllBaseline metrics:nil views:@{ @"about": self.aboutButton,
		@"privacy": self.privacyButton }];

	[NSLayoutConstraint deactivateConstraints:self.portraitConstraints];

	[self.view addConstraints:self.landscapeConstraints];

	[NSLayoutConstraint deactivateConstraints:self.landscapeConstraints];
	[NSLayoutConstraint activateConstraints:self.portraitConstraints];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[Apptentive.shared.backend engageCodePoint:[self codePointForEvent:ATInteractionAboutViewEventLabelClose] fromInteraction:nil userInfo:nil customData:nil extendedData:nil fromViewController:self];
}

- (IBAction)learnMore:(id)sender {
	NSURLComponents *components = [NSURLComponents componentsWithString:@"http://www.apptentive.com/"];
	components.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"source" value:[NSBundle mainBundle].bundleIdentifier]];

	[[UIApplication sharedApplication] openURL:components.URL];
}

- (IBAction)showPrivacy:(id)sender {
	NSURLComponents *components = [NSURLComponents componentsWithString:@"http://www.apptentive.com/privacy/"];
	components.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"source" value:[NSBundle mainBundle].bundleIdentifier]];

	[[UIApplication sharedApplication] openURL:components.URL];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	BOOL isCompactHeight = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact;
	BOOL isCompactWidth = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;

	self.imageViewHeightConstraint.constant = isCompactHeight ? 44.0 : 100.0;
	self.aboutLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.view.bounds) - 40.0;

	if (isCompactHeight && !isCompactWidth) {
		[NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
		[NSLayoutConstraint activateConstraints:self.landscapeConstraints];

		self.privacyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
	} else {
		[NSLayoutConstraint deactivateConstraints:self.portraitConstraints];
		[NSLayoutConstraint activateConstraints:self.portraitConstraints];

		self.privacyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	}
}

@end

NS_ASSUME_NONNULL_END
