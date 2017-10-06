//
//  NSMutableData+Types.m
//  Apptentive
//
//  Created by Alex Lementuev on 6/15/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "NSMutableData+Types.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSMutableData (Types)

- (void)apptentive_appendString:(NSString *)string {
	ApptentiveAssertNotNil(string, @"Attempted to append nil string");
	if (string != nil) {
		[self appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

- (void)apptentive_appendFormat:(NSString *)format, ... {
	ApptentiveAssertNotNil(format, @"Format is nil");
	if (format != nil) {
		va_list ap;
		va_start(ap, format);
		NSString *string = [[NSString alloc] initWithFormat:format arguments:ap];
		va_end(ap);

		[self apptentive_appendString:string];
	}
}

@end

NS_ASSUME_NONNULL_END
