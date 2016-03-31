//
//  ATInteractionUpgradeMessageViewController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 10/16/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUpgradeMessageViewController.h"
#import "ATConnect_Private.h"
#import "ATInteraction.h"
#import "ATBackend.h"
#import "ATUtilities.h"
#import "ATAboutViewController.h"

typedef enum {
	ATInteractionUpgradeMessageOkPressed,
} ATInteractionUpgradeMessageAction;

NSString *const ATInteractionUpgradeMessageEventLabelLaunch = @"launch";
NSString *const ATInteractionUpgradeMessageEventLabelClose = @"close";


@interface ATInteractionUpgradeMessageViewController ()

@property (strong, nonatomic) ATInteraction *upgradeMessageInteraction;

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


@implementation ATInteractionUpgradeMessageViewController

+ (instancetype)interactionUpgradeMessageViewControllerWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"UpgradeMessage"], @"Attempted to load an UpgradeMessageViewController with an interaction of type: %@", interaction.type);

	UINavigationController *navigationController = [[ATConnect storyboard] instantiateViewControllerWithIdentifier:@"UpgradeMessageNavigation"];
	ATInteractionUpgradeMessageViewController *result = (ATInteractionUpgradeMessageViewController *)navigationController.viewControllers.firstObject;

	result.upgradeMessageInteraction = interaction;

	return result;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// Borders
	self.appIconContainer.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1.0].CGColor;
	self.appIconContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	self.OKButton.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1.0].CGColor;
	self.OKButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;

	// App icon
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_app_icon"] boolValue]) {
		[self.appIconView setImage:[ATUtilities appIcon]];

		// Rounded corners
		UIImage *maskImage = [ATBackend imageNamed:@"at_update_icon_mask"];
		CALayer *maskLayer = [[CALayer alloc] init];
		maskLayer.contents = (id)maskImage.CGImage;
		maskLayer.frame = self.appIconView.bounds;
		self.appIconView.layer.mask = maskLayer;
		maskLayer = nil;
	} else {
		self.appIconView.hidden = YES;
	}

	// Powered by Apptentive logo
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_powered_by"] boolValue] && ![ATConnect sharedConnection].backend.hideBranding) {
		self.poweredByApptentiveLogo.text = ATLocalizedString(@"Powered by", @"Powered by followed by Apptentive logo.");
		UIImage *poweredByApptentiveIcon = [ATBackend imageNamed:@"at_update_logo"];
		[self.poweredByApptentiveIconView setImage:poweredByApptentiveIcon];
	} else {
		self.OKButtonBottomSpace.constant = 0.0;
		self.poweredByBackground.hidden = YES;
	}

	// Web view
	NSString *html = [self.upgradeMessageInteraction.configuration objectForKey:@"body"];
	[self.webView loadHTMLString:html baseURL:nil];
	self.webView.scrollView.showsHorizontalScrollIndicator = NO;
	self.webView.scrollView.showsVerticalScrollIndicator = NO;

	[self updateIconContainerHeightForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (IBAction)showAbout:(id)sender {
	[(ATNavigationController *)self.navigationController pushAboutApptentiveViewController];
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (IBAction)okButtonPressed:(id)sender {
	[self dismissAnimated:YES completion:NULL withAction:ATInteractionUpgradeMessageOkPressed];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATInteractionUpgradeMessageAction)action {
	[self.navigationController dismissViewControllerAnimated:animated completion:completion];

	[self.upgradeMessageInteraction engage:ATInteractionUpgradeMessageEventLabelClose fromViewController:self.presentingViewController];
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[newPresentingViewController presentViewController:self.navigationController animated:animated completion:nil];

	[self.upgradeMessageInteraction engage:ATInteractionUpgradeMessageEventLabelLaunch fromViewController:self.presentingViewController];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self updateIconContainerHeightForOrientation:toInterfaceOrientation];

	[UIView animateWithDuration:duration animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)updateIconContainerHeightForOrientation:(UIInterfaceOrientation)orientation {
	BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
	BOOL isIPad = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
	CGFloat topInset = 0.0;

	if (isIPad || isPortrait) {
		topInset = self.appIconView.hidden ? 50.0 : 90.0;

		self.appIconContainerHeight.constant = 124.0;
		self.OKButtonHeight.constant = 44.0;

		if (isIPad) {
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


- (void)viewDidUnload {
	[self setAppIconContainer:nil];
	[self setAppIconView:nil];
	[self setPoweredByApptentiveIconView:nil];
	[self setPoweredByApptentiveLogo:nil];
	[self setPoweredByBackground:nil];
	[self setPoweredByHeight:nil];
	[self setWebView:nil];

	[self setAppIconContainerHeight:nil];
	[self setOKButtonBottomSpace:nil];
	[self setOKButtonHeight:nil];
	[self setPoweredByBottomSpace:nil];

	[super viewDidUnload];
}
@end
