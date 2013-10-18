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

@interface ATInteractionUpgradeMessageViewController ()

@end

@implementation ATInteractionUpgradeMessageViewController

- (id)initWithInteraction:(ATInteraction *)interaction {
	NSAssert([interaction.type isEqualToString:@"UpgradeMessage"], @"Attempted to load an UpgradeMessageViewController with an interaction of type: %@", interaction.type);
	self = [super initWithNibName:@"ATInteractionUpgradeMessageViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
		_upgradeMessageInteraction = interaction;
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// TODO: Blur the background image
	
	// App icon
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_app_icon"] boolValue]) {
		[self.appIconView setImage:[self appIcon]];
	}
	
	// Powered by Apptentive icon
	// TODO: remove footer area if icon is not shown?
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_powered_by"] boolValue]) {
		self.poweredByApptentiveIconView.contentMode = UIViewContentModeScaleAspectFit;
		UIImage *poweredByApptentiveIcon = [ATBackend imageNamed:@"at_apptentive_logo"];
		[self.poweredByApptentiveIconView setImage:poweredByApptentiveIcon];
	}
		
	// Web view
	NSString *html = [self.upgradeMessageInteraction.configuration objectForKey:@"body"];
	[self.webView loadHTMLString:html baseURL:nil];

	// Rounded top corners of webview
	UIBezierPath *contentMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(10.0, 10.0)];
	CAShapeLayer *contentMaskLayer = [CAShapeLayer layer];
	contentMaskLayer.frame = self.webView.bounds;
	contentMaskLayer.path = contentMaskPath.CGPath;
	self.contentView.layer.mask = contentMaskLayer;
	
	// Rounded bottom corners of OK button
	UIBezierPath *buttonMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.okButtonBackgroundView.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
	CAShapeLayer *buttonMaskLayer = [CAShapeLayer layer];
	buttonMaskLayer.frame = self.okButtonBackgroundView.bounds;
	buttonMaskLayer.path = buttonMaskPath.CGPath;
	self.okButtonBackgroundView.layer.mask = buttonMaskLayer;
	
}

- (UIImage *)appIcon {
	NSArray *appIconFileNames = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
	NSLog(@"%@", appIconFileNames);
	
	// TODO: need to select the best-qualitiy image...
	UIImage *appIcon = [UIImage imageNamed:[appIconFileNames objectAtIndex:0]];
	return appIcon;
}

- (IBAction)okButtonPressed:(id)sender
{
	//[self.delegate messagePanelDidCancel:self];
	[self dismissAnimated:YES completion:NULL withAction:nil];
	//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidCancelNotification object:self userInfo:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATMessagePanelDismissAction)action {
	CGPoint endingPoint = [self offscreenPositionOfView];
		
	CGFloat duration = 0;
	if (animated) {
		duration = 0.3;
	}
	
	[UIView animateWithDuration:duration animations:^(void){
		self.view.center = endingPoint;
	} completion:^(BOOL finished) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
		[presentingViewController.view setUserInteractionEnabled:YES];
		[self.window resignKeyWindow];
		[self.window removeFromSuperview];
		self.window.hidden = YES;
		//[[UIApplication sharedApplication] setStatusBarStyle:startingStatusBarStyle];
		//[self teardown];
		[self release];
		
		if (completion) {
			completion();
		}
		//[self.delegate messagePanel:self didDismissWithAction:action];
	}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
