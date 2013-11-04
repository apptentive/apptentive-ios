//
//  NSObject+ATSwizzle.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 11/3/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "NSObject+ATSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (ATSwizzle)

- (IMP)swizzleSelector:(SEL)originalSelector withIMP:(IMP)newIMP {
	Class class = [self class];
	Method originalMethod = class_getInstanceMethod(class, originalSelector);
	IMP originalIMP = method_getImplementation(originalMethod);
	
	if (!class_addMethod([self class], originalSelector, newIMP, method_getTypeEncoding(originalMethod))) {
		method_setImplementation(originalMethod, newIMP);
	}
	
	return originalIMP;
}

@end
