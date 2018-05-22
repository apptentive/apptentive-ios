//
//  ApptentiveClass.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/8/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveInvocation.h"
#import "ApptentiveDefines.h"

@implementation ApptentiveInvocation

+ (BOOL)classAvailable:(NSString *)className {
	return className.length > 0 && NSClassFromString(className) != nil;
}

+ (nullable instancetype)fromClassName:(NSString *)className {
	Class cls = NSClassFromString(className);
	return cls != nil ? [[self alloc] initWithTarget:cls] : nil;
}

+ (nullable instancetype)fromObject:(id)object {
	return object != nil ? [[self alloc] initWithTarget:object] : nil;
}

- (instancetype)initWithTarget:(id)target {
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(target)
	
	self = [super init];
	if (self) {
		_target = target;
	}
	return self;
}

- (nullable id)invokeSelector:(NSString *)selectorName {
	if (selectorName.length == 0) {
		return nil;
	}
	
	@try {
		SEL selector = NSSelectorFromString(selectorName);
		if (selector != nil && [self.target respondsToSelector:selector]) {
			IMP method = [self.target methodForSelector:selector];
			id (*func)(id, SEL) = (void *)method;
			return func(self.target, selector);
		}
	} @catch (NSException *e) {
		ApptentiveLogError(@"Exception while invoking selector '%@' on target '%@'.\n%@", selectorName, self.target, e);
	}
	
	return nil;
}

- (nullable NSNumber *)invokeBoolSelector:(NSString *)selectorName {
	if (selectorName.length == 0) {
		return nil;
	}
	
	@try {
		SEL selector = NSSelectorFromString(selectorName);
		if (selector != nil && [self.target respondsToSelector:selector]) {
			IMP method = [self.target methodForSelector:selector];
			BOOL (*func)(id, SEL) = (void *)method;
			BOOL value = func(self.target, selector);
			return [NSNumber numberWithBool:value];
		}
	} @catch (NSException *e) {
		ApptentiveLogError(@"Exception while invoking selector '%@' on target '%@'.\n%@", selectorName, self.target, e);
	}
	
	return nil;
}

@end
