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

typedef enum {
	ATInteractionUpgradeMessageOkPressed,
} ATInteractionUpgradeMessageAction;

NSString *const ATInteractionUpgradeMessageEventLabelLaunch = @"launch";
NSString *const ATInteractionUpgradeMessageEventLabelClose = @"close";

@interface ATInteractionUpgradeMessageViewController ()

@property (nonatomic, retain, readonly) ATInteraction *upgradeMessageInteraction;

@property (nonatomic, retain) IBOutlet UIView *appIconContainer;
@property (nonatomic, retain) IBOutlet UIImageView *appIconBackgroundView;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *appIconHeight;
@property (nonatomic, retain) IBOutlet UIImageView *appIconView;
@property (nonatomic, retain) IBOutlet UIImageView *poweredByApptentiveIconView;
@property (nonatomic, retain) IBOutlet UILabel *poweredByApptentiveLogo;
@property (nonatomic, retain) IBOutlet UIView *poweredByBackground;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *poweredByHeight;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (IBAction)okButtonPressed:(id)sender;

@end

@implementation ATInteractionUpgradeMessageViewController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"UpgradeMessage"], @"Attempted to load an UpgradeMessageViewController with an interaction of type: %@", interaction.type);
	
	self = [super initWithNibName:@"ATInteractionUpgradeMessageViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		_upgradeMessageInteraction = [interaction copy];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if ([[ATConnect sharedConnection] tintColor]) {
		[self.view setTintColor:[[ATConnect sharedConnection] tintColor]];
	}
	
	// App icon
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_app_icon"] boolValue]) {
		[self.appIconView setImage:[ATUtilities appIcon]];
		[self.appIconBackgroundView setImage:[ATBackend imageNamed:@"at_update_icon_shadow"]];

		// Rounded corners
		UIImage *maskImage = [ATBackend imageNamed:@"at_update_icon_mask"];
		CALayer *maskLayer = [[CALayer alloc] init];
		maskLayer.contents = (id)maskImage.CGImage;
		maskLayer.frame = self.appIconView.bounds;
		self.appIconView.layer.mask = maskLayer;
		[maskLayer release], maskLayer = nil;
	} else {
		self.appIconHeight.constant = 0.0;
		self.appIconContainer.hidden = YES;
	}
	
	// Powered by Apptentive logo
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_powered_by"] boolValue] && ![ATBackend sharedBackend].hideBranding) {
		self.poweredByApptentiveLogo.text = ATLocalizedString(@"Powered by", @"Powered by followed by Apptentive logo.");
		UIImage *poweredByApptentiveIcon = [ATBackend imageNamed:@"at_update_logo"];
		[self.poweredByApptentiveIconView setImage:poweredByApptentiveIcon];
	} else {
		self.poweredByApptentiveIconView.hidden = YES;
		self.poweredByApptentiveLogo.hidden = YES;
		self.poweredByHeight.constant = 1.0 / [UIScreen mainScreen].scale;
	}
	
	// Web view
	NSString *html = [self.upgradeMessageInteraction.configuration objectForKey:@"body"];
	[self.webView loadHTMLString:html baseURL:nil];
}

- (IBAction)okButtonPressed:(id)sender {
	[self dismissAnimated:YES completion:NULL withAction:ATInteractionUpgradeMessageOkPressed];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATInteractionUpgradeMessageAction)action {
	[self dismissViewControllerAnimated:animated completion:completion];
	
	[self.upgradeMessageInteraction engage:ATInteractionUpgradeMessageEventLabelClose fromViewController:self.presentingViewController];
	
	[self release];
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	self.modalPresentationStyle = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
	[newPresentingViewController presentViewController:self animated:animated completion:nil];
	
	[self.upgradeMessageInteraction engage:ATInteractionUpgradeMessageEventLabelLaunch fromViewController:self.presentingViewController];
}

- (void)dealloc {
	[_upgradeMessageInteraction release];
	
	[_appIconContainer release];
	[_appIconBackgroundView release];
	[_appIconHeight release];
	[_appIconView release];
	[_poweredByApptentiveIconView release];
	[_poweredByApptentiveLogo release];
	[_poweredByBackground release];
	[_poweredByHeight release];
	[_webView release];
	
	[super dealloc];
}

@end
