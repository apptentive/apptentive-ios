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
#import "ATMessagePanelViewController.h"
#import "ATUtilities.h"
#import "UIImage+ATImageEffects.h"

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
	
	// Blurred background
	UIImage *screenshot = [ATUtilities screenshot];
	UIImage *blurred = [screenshot applyLightEffect];
	[self.backgroundImageView setImage:blurred];

	
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

	// Rounded top corners of content
	UIBezierPath *contentMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.view.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(10.0, 10.0)];
	CAShapeLayer *contentMaskLayer = [CAShapeLayer layer];
	contentMaskLayer.frame = self.webView.bounds;
	contentMaskLayer.path = contentMaskPath.CGPath;
	self.view.layer.mask = contentMaskLayer;
	
	// Rounded bottom corners of OK button
	UIBezierPath *buttonMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.okButtonBackgroundView.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.0, 10.0)];
	CAShapeLayer *buttonMaskLayer = [CAShapeLayer layer];
	buttonMaskLayer.frame = self.okButtonBackgroundView.bounds;
	buttonMaskLayer.path = buttonMaskPath.CGPath;
	self.okButtonBackgroundView.layer.mask = buttonMaskLayer;
	
}

- (UIImage *)appIcon {
	NSArray *appIconFileNames = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"];
	//NSLog(@"%@", appIconFileNames);
	
#warning Non-retina. Need to select the best-qualitiy image...
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
		self.alertView.center = endingPoint;
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

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
	CALayer *l = self.alertView.layer;
		
	UIWindow *parentWindow = [self windowForViewController:presentingViewController];
	if (!parentWindow) {
		ATLogError(@"Unable to find parentWindow!");
	}
	if (originalPresentingWindow != parentWindow) {
		[originalPresentingWindow release], originalPresentingWindow = nil;
		originalPresentingWindow = [parentWindow retain];
	}
		
	CGRect animationBounds = CGRectZero;
	CGPoint animationCenter = CGPointZero;
	
	CGAffineTransform t = [ATMessagePanelViewController viewTransformInWindow:parentWindow];
	self.window.transform = t;
	self.window.hidden = NO;
	[parentWindow resignKeyWindow];
	[self.window makeKeyAndVisible];
	animationBounds = parentWindow.bounds;
	animationCenter = parentWindow.center;
	
	// Animate in from above.
	self.window.bounds = animationBounds;
	self.window.windowLevel = UIWindowLevelNormal;
	CGPoint center = animationCenter;
	center.y = ceilf(center.y);
	
	CGRect endingFrame = [[UIScreen mainScreen] applicationFrame];
	
	[self positionInWindow];
	self.window.center = CGPointMake(CGRectGetMidX(endingFrame), CGRectGetMidY(endingFrame));
	self.view.center = [self offscreenPositionOfView];
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	
	l.cornerRadius = 10.0;
	l.backgroundColor = [UIColor whiteColor].CGColor;
	
	l.masksToBounds = YES;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	}
	[UIView animateWithDuration:0.3 animations:^(void){
		self.window.center = newViewCenter;
		self.alertView.center = newViewCenter;
	} completion:^(BOOL finished) {
		self.window.hidden = NO;
	}];
		
	//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidShowNotification object:self userInfo:nil];
}

- (UIWindow *)windowForViewController:(UIViewController *)viewController {
	UIWindow *result = nil;
	UIView *rootView = [viewController view];
	if (rootView.window) {
		result = rootView.window;
	}
	if (!result) {
		result = [self findMainWindowPreferringMainScreen:YES];
		if (!result) {
			result = [self findMainWindowPreferringMainScreen:NO];
		}
	}
	return result;
}

- (CGRect)onscreenRectOfView {
	return [[UIScreen mainScreen] bounds];
}

- (CGPoint)offscreenPositionOfView {
	CGRect f = [self onscreenRectOfView];
	NSLog(@"onscreen: (%f, %f) / (%f, %f)", f.origin.x, f.origin.y, f.size.width, f.size.height);

	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	CGFloat statusBarHeight = MIN(statusBarSize.height, statusBarSize.width);
	CGFloat viewHeight = f.size.height;
	
	CGRect offscreenViewRect = f;
	offscreenViewRect.origin.y = -(viewHeight + statusBarHeight);
	CGPoint offscreenPoint = CGPointMake(CGRectGetMidX(offscreenViewRect), CGRectGetMidY(offscreenViewRect));
	
	NSLog(@"Offscreen: %f, %f", offscreenPoint.x, offscreenPoint.y);
	
	return offscreenPoint;
}

- (BOOL)isIPhoneAppInIPad {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		NSString *model = [[UIDevice currentDevice] model];
		if ([model isEqualToString:@"iPad"]) {
			return YES;
		}
	}
	return NO;
}

- (void)positionInWindow {
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	CGFloat angle = 0.0;
	CGRect newFrame = originalPresentingWindow.bounds;
	CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			angle = M_PI;
			newFrame.size.height -= statusBarSize.height;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			angle = - M_PI / 2.0f;
			newFrame.origin.x += statusBarSize.width;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationLandscapeRight:
			angle = M_PI / 2.0f;
			newFrame.size.width -= statusBarSize.width;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			angle = 0.0;
			newFrame.origin.y += statusBarSize.height;
			newFrame.size.height -= statusBarSize.height;
			break;
	}
}

@end
