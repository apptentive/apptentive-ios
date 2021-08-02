//
//  UIAlertController+Apptentive.m
//  Apptentive
//
//  Created by Alex Lementuev on 8/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "UIAlertController+Apptentive.h"
#import "UIWindow+Apptentive.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIAlertController (Apptentive_Private)

@property (nullable, strong, nonatomic) UIWindow *apptentiveAlertWindow;

@end


@implementation UIAlertController (Apptentive_Private)

@dynamic apptentiveAlertWindow;

- (void)setApptentiveAlertWindow:(nullable UIWindow *)window {
	objc_setAssociatedObject(self, @selector(apptentiveAlertWindow), window, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable UIWindow *)apptentiveAlertWindow {
	return objc_getAssociatedObject(self, @selector(apptentiveAlertWindow));
}

@end


@implementation UIAlertController (Apptentive)

- (void)apptentive_presentAnimated:(BOOL)animated completion:(void (^__nullable)(void))completion {
	self.apptentiveAlertWindow = [UIWindow apptentive_windowWithRootViewController:[[UIViewController alloc] init]];
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
