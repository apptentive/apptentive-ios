//
//  ATPendingMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPendingMessage.h"

#define kATPendingMessageCodingVersion 1

@implementation ATPendingMessage
@synthesize body;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.body = [coder decodeObjectForKey:@"body"];
	}
	return self;
}

- (void)dealloc {
	[body release], body = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPendingMessageCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.body forKey:@"body"];
}

- (NSDictionary *)apiJSON {
	return @{@"message":@{@"body":self.body}};
}
@end
