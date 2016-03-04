//
//  ATHUDViewController.m
//  ATHUD
//
//  Created by Frank Schmitt on 3/2/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ATHUDViewController.h"
#import "ATPassThroughWindow.h"

@interface ATHUDViewController ()

@property (strong, nonatomic) IBOutlet UIView *HUDView;
@property (strong, nonatomic) UIWindow *hostWindow;
@property (strong, nonatomic) UIWindow *shadowWindow;
@property (strong, nonatomic) NSTimer *hideTimer;
@property (strong, nonatomic) UIGestureRecognizer *tapGestureRecognizer;

@end

static ATHUDViewController *currentHUD;

@implementation ATHUDViewController

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [UIColor clearColor];

	self.HUDView = [[UIView alloc] initWithFrame:CGRectZero];
	self.HUDView.translatesAutoresizingMaskIntoConstraints = NO;

	self.HUDView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	self.HUDView.layer.cornerRadius = 12.0;

	[self.view addSubview:self.HUDView];

	[self.view addConstraints:@[
								[NSLayoutConstraint constraintWithItem:self.HUDView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
								[NSLayoutConstraint constraintWithItem:self.HUDView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]
								]];

	self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.textLabel.textColor = [UIColor whiteColor];
	self.textLabel.font = [UIFont systemFontOfSize:15.0];

	self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;

	self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

	[self.HUDView addSubview:self.textLabel];
	[self.HUDView addSubview:self.imageView];

	NSDictionary *views = @{ @"image": self.imageView, @"label": self.textLabel };

	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(44)-[image]-(36)-[label]-(44)-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=44)-[image]-(>=44)-|" options:0 metrics:nil views:views]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=44)-[label]-(>=44)-|" options:0 metrics:nil views:views]];

	[self.HUDView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)]];
}

- (void)showInAlertWindow {
	self.interval = self.interval ?: 2.0;
	self.animationDuration = fmin(self.animationDuration ?: 0.25, self.interval / 2.0);

	self.hostWindow =  [[ATPassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.hostWindow.hidden = NO;

	self.hostWindow.rootViewController = self;

	self.hostWindow.windowLevel = UIWindowLevelAlert;
	self.hostWindow.backgroundColor = [UIColor clearColor];
	self.hostWindow.frame = [UIScreen mainScreen].bounds;

	self.HUDView.alpha = 0.0;
	[UIView animateWithDuration:self.animationDuration animations:^{
		self.HUDView.alpha = 1;
	}];

	self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(hide:) userInfo:nil repeats:NO];
}

- (IBAction)hide:(id)sender {
	[self.hideTimer invalidate];
	[UIView animateWithDuration:self.animationDuration animations:^{
		self.HUDView.alpha = 0;
	} completion:^(BOOL finished) {
		[self.hostWindow resignKeyWindow];
		self.hostWindow.hidden = YES;
		self.hostWindow = nil;
	}];
}

- (BOOL)shouldAutorotate {
	return YES;
}

@end
