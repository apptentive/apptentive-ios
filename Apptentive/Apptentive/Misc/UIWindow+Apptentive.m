//
//  UIWindow+Apptentive.m
//  Apptentive
//
//  Created by Frank Schmitt on 7/29/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

#import "UIWindow+Apptentive.h"

@implementation UIWindow (Apptentive)

+ (instancetype)apptentive_windowWithRootViewController:(UIViewController *)rootViewController {
	UIWindow *window;
	
	if (@available(iOS 13.0, *)) {
		// Look for an active foreground scene.
		for (UIScene *scene in UIApplication.sharedApplication.connectedScenes.allObjects) {
			if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
				window = [[self alloc] initWithWindowScene:(UIWindowScene *)scene];
			}
		}
		
		if (window == nil) {
			// Settle for an inactive foreground scene.
			for (UIScene *scene in UIApplication.sharedApplication.connectedScenes.allObjects) {
				if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundInactive) {
					window = [[self alloc] initWithWindowScene:(UIWindowScene *)scene];
				}
			}
		}
	}
	
	if (window == nil) {
		// Fall back to a standard UIWindow object (won't work with scene-based apps).
		window = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
	}
	
	window.rootViewController = rootViewController;
	window.windowLevel = UIWindowLevelAlert + 1;
	
	return window;
}

@end
