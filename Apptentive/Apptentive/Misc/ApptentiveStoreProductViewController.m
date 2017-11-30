//
//  ApptentiveStoreProductViewController.m
//  Apptentive
//
//  Created by Alex Lementuev on 8/31/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveStoreProductViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface ApptentiveStoreProductViewController ()

@property (nullable, strong, nonatomic) UIWindow *apptentiveAlertWindow;

@end


@implementation ApptentiveStoreProductViewController

- (void)presentAnimated:(BOOL)animated completion:(void (^__nullable)(void))completion {
	self.apptentiveAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.apptentiveAlertWindow.rootViewController = [[UIViewController alloc] init];
	self.apptentiveAlertWindow.windowLevel = UIWindowLevelAlert + 1;
	[self.apptentiveAlertWindow makeKeyAndVisible];
	[self.apptentiveAlertWindow.rootViewController presentViewController:self animated:animated completion:completion];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	if (self.presentingViewController == nil) {
		self.apptentiveAlertWindow.hidden = YES;
		self.apptentiveAlertWindow = nil;
	}
}

@end

NS_ASSUME_NONNULL_END
