//
//  ApptentiveInteractionUpgradeMessageViewController.m
//  Apptentive
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInteractionUpgradeMessageViewController.h"
#import "ApptentiveAboutViewController.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveBackend.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
	ATInteractionUpgradeMessageOkPressed,
} ATInteractionUpgradeMessageAction;

NSString *const ATInteractionUpgradeMessageEventLabelClose = @"close";


@interface ApptentiveInteractionUpgradeMessageViewController ()


@property (strong, nonatomic) IBOutlet UIView *appIconContainer;
@property (strong, nonatomic) IBOutlet UIButton *OKButton;
@property (strong, nonatomic) IBOutlet UIImageView *appIconView;
@property (strong, nonatomic) IBOutlet UIImageView *poweredByApptentiveIconView;
@property (strong, nonatomic) IBOutlet UILabel *poweredByApptentiveLogo;
@property (strong, nonatomic) IBOutlet UIView *poweredByBackground;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *poweredByHeight;
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *appIconContainerHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *OKButtonBottomSpace;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *OKButtonHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *poweredByBottomSpace;

@end


@implementation ApptentiveInteractionUpgradeMessageViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Borders
	self.appIconContainer.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1.0].CGColor;
	self.appIconContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.OKButton.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1.0].CGColor;
	self.OKButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	// App icon
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_app_icon"] boolValue]) {
		[self.appIconView setImage:[ApptentiveUtilities appIcon]];

		// Rounded corners
		UIImage *maskImage = [ApptentiveUtilities imageNamed:@"at_update_icon_mask"];
		CALayer *maskLayer = [[CALayer alloc] init];
		maskLayer.contents = (id)maskImage.CGImage;
		maskLayer.frame = self.appIconView.bounds;
		self.appIconView.layer.mask = maskLayer;
		maskLayer = nil;
	} else {
		self.appIconView.hidden = YES;
	}

	// Powered by Apptentive logo
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_powered_by"] boolValue] && !Apptentive.shared.backend.configuration.hideBranding) {
		self.poweredByApptentiveLogo.text = ApptentiveLocalizedString(@"Powered by", @"Powered by followed by Apptentive logo.");
		UIImage *poweredByApptentiveIcon = [ApptentiveUtilities imageNamed:@"at_update_logo"];
		[self.poweredByApptentiveIconView setImage:poweredByApptentiveIcon];
	} else {
		self.OKButtonBottomSpace.constant = 0.0;
		self.poweredByBackground.hidden = YES;
	}

	// Web view
	NSString *html = [self.upgradeMessageInteraction.configuration objectForKey:@"body"];
	[self.webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://"]];
	self.webView.scrollView.showsHorizontalScrollIndicator = NO;
	self.webView.scrollView.showsVerticalScrollIndicator = NO;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showAbout:(id)sender {
	[(ApptentiveNavigationController *)self.navigationController pushAboutApptentiveViewController];
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)okButtonPressed:(id)sender {
	[self dismissAnimated:YES completion:nil withAction:ATInteractionUpgradeMessageOkPressed];

	self.interactionController = nil;
}

- (void)dismissAnimated:(BOOL)animated completion:(nullable void (^)(void))completion withAction:(ATInteractionUpgradeMessageAction)action {
	[self.navigationController dismissViewControllerAnimated:animated completion:completion];

	[Apptentive.shared.backend engage:ATInteractionUpgradeMessageEventLabelClose fromInteraction:self.upgradeMessageInteraction fromViewController:self.presentingViewController];
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];

	BOOL isRegularHeight = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular;
	CGFloat topInset = 0.0;

	if (isRegularHeight) {
		topInset = self.appIconView.hidden ? 50.0 : 90.0;

		self.appIconContainerHeight.constant = 124.0;
		self.OKButtonHeight.constant = 44.0;

		if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			self.OKButtonBottomSpace.constant = 0.0;
			self.poweredByBottomSpace.constant = 44.0;
		}
	} else {
		topInset = self.appIconView.hidden ? 33.0 : 73.0;

		self.appIconContainerHeight.constant = 73.0;
		self.OKButtonHeight.constant = 33.0;
	}

	self.webView.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0.0, 0.0, 0.0);
}

@end

NS_ASSUME_NONNULL_END
