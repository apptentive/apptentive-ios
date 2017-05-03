//
//  ApptentiveAssert.m
//  Apptentive
//
//  Created by Alex Lementuev on 4/28/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveAssert.h"

void __ApptentiveAssertHelper(const char* expression, const char* file, int line, const char* function, ...) {
    // TODO: better implemetation
    va_list ap;
    va_start(ap, function);
    NSString *message = va_arg(ap, NSString *);
    if (message) {
        message = [[NSString alloc] initWithFormat:message arguments:ap];
    }
    va_end(ap);
    
    NSLog(@"Assertion failed (%s:%d): %@", file, line, message);
    abort();
}
