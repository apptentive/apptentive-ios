//
//  ApptentiveIndentPrinter.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/21/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveIndentPrinter.h"

@interface ApptentiveIndentPrinter ()

@property (readwrite, nonatomic) NSInteger indentLevel;
//@property (readwrite, nonatomic) NSString *output;
@property (strong, nonatomic) NSMutableArray *lines;

@end

@implementation ApptentiveIndentPrinter

- (instancetype)init
{
	self = [super init];
	if (self) {
		_indentWidth = 2;
		_lines = [NSMutableArray array];
	}
	return self;
}

- (void)indent {
	self.indentLevel ++;
}

- (void)outdent {
	if (self.indentLevel >= 1) {
		self.indentLevel --;
	} else {
		ApptentiveAssertFail(@"Attempting to outdent past zero");
	}
}

- (NSString *)indentationString {
	return [@"" stringByPaddingToLength:self.indentLevel * self.indentWidth withString:@" " startingAtIndex:0];
}

- (void)appendString:(NSString *)string {
	[self.lines addObject:[NSString stringWithFormat:@"%@%@", [self indentationString], string]];
}

- (void)appendFormat:(NSString *)format, ... {
	va_list args;
	va_start(args, format);
	NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);

	[self appendString:string];
}

- (NSString *)output {
	return [self.lines componentsJoinedByString:@"\n"];
}

@end
