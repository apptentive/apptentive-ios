//
//  UIAlertController+Apptentive.m
//  Apptentive
//
//  Created by Alex Lementuev on 8/29/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "UIAlertController+Apptentive.h"

#import <objc/runtime.h>

@interface UIAlertController (Apptentive_Private)

@property (nonatomic, strong) UIWindow *apptentiveAlertWindow;

@end

@implementation UIAlertController (Apptentive_Private)

@dynamic apptentiveAlertWindow;

- (void)setApptentiveAlertWindow:(UIWindow *)window {
	objc_setAssociatedObject(self, @selector(apptentiveAlertWindow), window, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIWindow *)apptentiveAlertWindow {
	return objc_getAssociatedObject(self, @selector(apptentiveAlertWindow));
}

@end

@implementation UIAlertController (Apptentive)

- (void)apptentive_presentAnimated:(BOOL)animated {
	self.apptentiveAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.apptentiveAlertWindow.rootViewController = [[UIViewController alloc] init];
	self.apptentiveAlertWindow.windowLevel = UIWindowLevelAlert + 1;
	[self.apptentiveAlertWindow makeKeyAndVisible];
	[self.apptentiveAlertWindow.rootViewController presentViewController:self animated:animated completion:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	self.apptentiveAlertWindow.hidden = YES;
	self.apptentiveAlertWindow = nil;
}

@end
