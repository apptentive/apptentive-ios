//
//  ApptentiveAssert.m
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAssert.h"

NS_ASSUME_NONNULL_BEGIN


static ApptentiveAssertionCallback _callback;

void ApptentiveSetAssertionCallback(ApptentiveAssertionCallback callback) {
	_callback = callback;
}

void __ApptentiveAssertHelper(const char *expression, const char *file, int line, const char *function, ...) {
	// TODO: better implemetation
	va_list ap;
	va_start(ap, function);
	NSString *message = va_arg(ap, NSString *);
	if (message) {
		message = [[NSString alloc] initWithFormat:message arguments:ap];
	}
	va_end(ap);

	NSLog(@"Apptentive Assertion failed (%s:%d): %@", file, line, message);
	if (_callback) {
		_callback([NSString stringWithUTF8String:file], line, message);
	}
}

NS_ASSUME_NONNULL_END
