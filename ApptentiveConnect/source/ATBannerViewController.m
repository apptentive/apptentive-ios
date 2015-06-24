//
//  BannerViewController.m
//  TestBanner
//
//  Created by Frank Schmitt on 6/17/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "ATBannerViewController.h"
#import "ATConnect_Private.h"

#define DISPLAY_DURATION 3.0
#define ANIMATION_DURATION 0.33

@interface ATBannerViewController ()

@property (strong, nonatomic) ATBannerViewController *cyclicReference;
@property (strong, nonatomic) NSTimer *hideTimer;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet UIView *bannerView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconSpacingConstraint;

@end

@implementation ATBannerViewController

+ (void)showWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message delegate:(id<ATBannerViewControllerDelegate>)delegate {
	static ATBannerViewController *_currentBanner;
	
	if (_currentBanner != nil) {
		[_currentBanner hide:self];
	}
	
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MessageCenter" bundle:[ATConnect resourceBundle]];
	ATBannerViewController *banner = [storyboard instantiateViewControllerWithIdentifier:@"Banner"];
	banner.delegate = delegate;
	
	[banner showWithImage:image title:title message:message];
}

- (void)showWithImage:(UIImage *)image title:(NSString *)title message:(NSString *)message {
	UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;

	self.window  = [[UIWindow alloc] initWithFrame:mainWindow.bounds];
	self.window.rootViewController = self;
	self.window.windowLevel = UIWindowLevelAlert;
	
	[self.window makeKeyAndVisible];
	
	self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:DISPLAY_DURATION target:self selector:@selector(hide:) userInfo:nil repeats:NO];
	
	self.topConstraint.constant = -CGRectGetHeight(self.bannerView.bounds);
	[self.view layoutIfNeeded];

	self.topConstraint.constant = 0;
	
	[UIView animateWithDuration:ANIMATION_DURATION animations:^{
		[self.view layoutIfNeeded];
		self.window.frame = self.bannerView.frame;
	}];
	
	self.hasIcon = (image != nil);
	self.imageView.image = image;
	self.titleLabel.text = title;
	self.messageLabel.text = message;
}

- (void)dealloc {
	[self.hideTimer invalidate];
}

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
	return NO;
}

- (void)viewDidLayoutSubviews {
	self.imageView.layer.cornerRadius = CGRectGetHeight(self.imageView.bounds) / 2.0;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self.window resignKeyWindow];
	self.window.rootViewController = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.window makeKeyAndVisible];
	self.window.rootViewController = self;
	self.window.frame = self.bannerView.bounds;
}

- (void)setHasIcon:(BOOL)hasIcon {
	self.imageView.hidden = !hasIcon;
	
	if (hasIcon) {
		if (![self.bannerView.constraints containsObject:self.iconSpacingConstraint]) {
			[self.bannerView addConstraint:self.iconSpacingConstraint];
		}
		self.imageView.hidden = NO;
	} else {
		if ([self.bannerView.constraints containsObject:self.iconSpacingConstraint]) {
			[self.bannerView removeConstraint:self.iconSpacingConstraint];
		}
		self.imageView.hidden = YES;
	}
}

#pragma mark - Actions

- (IBAction)hide:(id)sender {
	self.topConstraint.constant = -CGRectGetHeight(self.bannerView.bounds);

	[UIView animateWithDuration:ANIMATION_DURATION animations:^{
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.window resignKeyWindow];
		
		self.window.rootViewController = nil;
	}];
}

- (IBAction)tap:(id)sender {
	[self.delegate userDidTapBanner:self];
	
	[self hide:sender];
}

@end
