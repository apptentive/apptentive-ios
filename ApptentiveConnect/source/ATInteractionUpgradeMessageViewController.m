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

typedef enum {
	ATInteractionUpgradeMessageOkPressed,
} ATInteractionUpgradeMessageAction;

@interface ATInteractionUpgradeMessageViewController ()
- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen;
- (UIWindow *)windowForViewController:(UIViewController *)viewController;
- (void)statusBarChanged:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Blurred background
	UIImage *screenshot = [ATUtilities screenshot];
	UIImage *blurred = [screenshot applyLightEffect];
	[self.backgroundImageView setImage:blurred];
	
	// App icon
	if ([[self.upgradeMessageInteraction.configuration objectForKey:@"show_app_icon"] boolValue]) {
		[self.appIconView setImage:[ATUtilities appIcon]];
		
		// Rounded corners
		CGRect rect = self.appIconView.bounds;
		CGFloat radius = MIN(rect.size.width, rect.size.height) / 4;
		UIBezierPath *appIconMaskPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
		CAShapeLayer *appIconMaskLayer = [CAShapeLayer layer];
		appIconMaskLayer.frame = self.webView.bounds;
		appIconMaskLayer.path = appIconMaskPath.CGPath;
		self.appIconView.layer.mask = appIconMaskLayer;
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

- (IBAction)okButtonPressed:(id)sender {
	//[self.delegate messagePanelDidCancel:self];
	[self dismissAnimated:YES completion:NULL withAction:ATInteractionUpgradeMessageOkPressed];
	//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidCancelNotification object:self userInfo:nil];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)(void))completion withAction:(ATInteractionUpgradeMessageAction)action {
	CGPoint endingPoint = [self offscreenPositionOfView];
	
	CGRect poweredByEndingFrame = self.poweredByBackground.frame;
	poweredByEndingFrame = CGRectOffset(self.poweredByBackground.frame, 0, poweredByEndingFrame.size.height);
		
	CGFloat duration = 0;
	if (animated) {
		duration = 0.3;
	}
	
	[UIView animateWithDuration:duration animations:^(void){
		self.alertView.center = endingPoint;
		self.backgroundImageView.alpha = 0.0;
		self.poweredByBackground.frame = poweredByEndingFrame;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentFromViewController:(UIViewController *)newPresentingViewController animated:(BOOL)animated {
	[self retain];
	// For viewDidLoad…
	__unused UIView *v = [self view];
	
	if (presentingViewController != newPresentingViewController) {
		[presentingViewController release], presentingViewController = nil;
		presentingViewController = [newPresentingViewController retain];
		[presentingViewController.view setUserInteractionEnabled:NO];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarChanged:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
		
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
	
	CGAffineTransform t = [ATUtilities viewTransformInWindow:parentWindow];
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
	self.alertView.center = [self offscreenPositionOfView];
	
	CGRect poweredByEndingFrame = self.poweredByBackground.frame;
	self.poweredByBackground.frame = CGRectOffset(poweredByEndingFrame, 0, poweredByEndingFrame.size.height);
	
	CGRect newFrame = [self onscreenRectOfView];
	CGPoint newViewCenter = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
	
	CALayer *l = self.alertView.layer;
	l.cornerRadius = 10.0;
	l.backgroundColor = [UIColor clearColor].CGColor;
	l.masksToBounds = YES;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	} else {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	}
	self.backgroundImageView.alpha = 0;
	[UIView animateWithDuration:0.3 animations:^(void){
//		self.window.center = newViewCenter;
		self.alertView.center = newViewCenter;
		self.poweredByBackground.frame = poweredByEndingFrame;
		self.backgroundImageView.alpha = 1;
	} completion:^(BOOL finished) {
		self.window.hidden = NO;
	}];
		
	//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterIntroDidShowNotification object:self userInfo:nil];
}

- (CGRect)onscreenRectOfView {
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGRect alertRect = self.alertView.bounds;
	alertRect.size.height = screenBounds.size.height - 30 - self.poweredByBackground.bounds.size.height;
	alertRect.origin.y = 20;
	alertRect.origin.x = floor((screenBounds.size.width - alertRect.size.width)*0.5);
	return alertRect;
}

- (CGPoint)offscreenPositionOfView {
	CGRect f = [self onscreenRectOfView];
	NSLog(@"onscreen: %@", NSStringFromCGRect(f));
	CGRect offscreenViewRect = CGRectOffset(f, 0, -(f.origin.y + f.size.height + 20));
	
	CGPoint offscreenPoint = CGPointMake(CGRectGetMidX(offscreenViewRect), CGRectGetMidY(offscreenViewRect));
	
	NSLog(@"Offscreen: %@", NSStringFromCGPoint(offscreenPoint));
	
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
#warning Do layout adjustment here.
}

- (UIWindow *)findMainWindowPreferringMainScreen:(BOOL)preferMainScreen {
	UIApplication *application = [UIApplication sharedApplication];
	for (UIWindow *tmpWindow in [[application windows] reverseObjectEnumerator]) {
		if (tmpWindow.rootViewController || tmpWindow.isKeyWindow) {
			if (preferMainScreen && [tmpWindow respondsToSelector:@selector(screen)]) {
				if (tmpWindow.screen && [tmpWindow.screen isEqual:[UIScreen mainScreen]]) {
					return tmpWindow;
				}
			} else {
				return tmpWindow;
			}
		}
	}
	return nil;
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

- (void)statusBarChanged:(NSNotification *)notification {
	[self positionInWindow];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (self.window.hidden == NO) {
		[self retain];
		[self unhide:NO];
	}
	[pool release], pool = nil;
}

- (void)unhide:(BOOL)animated {
	self.window.windowLevel = UIWindowLevelNormal;
	self.window.hidden = NO;
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 1.0;
		} completion:^(BOOL complete){
			[self finishUnhide];
		}];
	} else {
		[self finishUnhide];
	}
}

- (void)hide:(BOOL)animated {
	[self retain];
	
	self.window.windowLevel = UIWindowLevelNormal;
	
	if (animated) {
		[UIView animateWithDuration:0.2 animations:^(void){
			self.window.alpha = 0.0;
		} completion:^(BOOL finished) {
			[self finishHide];
		}];
	} else {
		[self finishHide];
	}
}

- (void)finishHide {
	self.window.alpha = 0.0;
	self.window.hidden = YES;
	[self.window removeFromSuperview];
}

- (void)finishUnhide {
	self.window.alpha = 1.0;
	[self.window makeKeyAndVisible];
	[self positionInWindow];
	[self release];
}
- (void)dealloc {
	[_contentView release];
	[_poweredByBackground release];
	[super dealloc];
}
- (void)viewDidUnload {
	[self setContentView:nil];
	[self setPoweredByBackground:nil];
	[super viewDidUnload];
}
@end
