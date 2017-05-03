//
//  ApptentiveAssert.m
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAssert.h"

void __ApptentiveAssertHelper(const char *expression, const char *file, int line, const char *function, ...) {
	// TODO: better implemetation
	NSLog(@"Assertion failed: %s:%d", file, line);
	abort();
}
