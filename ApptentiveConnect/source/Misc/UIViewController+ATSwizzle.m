//
//  UIViewController+ATSwizzle.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 11/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "UIViewController+ATSwizzle.h"
#import "NSObject+ATSwizzle.h"
#import "ATInteractionUpgradeMessageViewController.h"

@implementation UIViewController (ATSwizzle)

typedef void (*voidIMP) (id, SEL, ...);
static voidIMP originalDidRotate = NULL;

- (void)swizzleDidRotateFromInterfaceOrientation {
	if (!originalDidRotate) {
		SEL sel = @selector(didRotateFromInterfaceOrientation:);
		originalDidRotate = (void *)[self swizzleSelector:sel withIMP:(IMP)swizzledDidRotateFromInterfaceOrientation];
	}	
}

static void swizzledDidRotateFromInterfaceOrientation(id self, SEL _cmd, id  observer, SEL selector, NSString *name, id object) {
	NSAssert(originalDidRotate, @"Original `didRotateFromInterfaceOrientation:` method was not found.");
    
    // New implementation
	[[NSNotificationCenter defaultCenter] postNotificationName:ATInteractionUpgradeMessagePresentingViewControllerSwizzledDidRotateNotification object:nil];
    
    // Original implementation
	if (originalDidRotate) {
        originalDidRotate(self, _cmd, observer, selector, name, object);
	}
}

@end
