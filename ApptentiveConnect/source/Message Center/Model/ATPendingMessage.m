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
@synthesize pendingMessageID;
@synthesize creationTime;

- (id)init {
	if ((self = [super init])) {
		creationTime = [[NSDate date] timeIntervalSince1970];
		
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		self.pendingMessageID = [NSString stringWithFormat:@"pending-message:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.body = [coder decodeObjectForKey:@"body"];
		self.pendingMessageID = [coder decodeObjectForKey:@"pendingMessageID"];
		self.creationTime = (NSTimeInterval)[coder decodeDoubleForKey:@"creationTime"];
	}
	return self;
}

- (void)dealloc {
	[body release], body = nil;
	[pendingMessageID release], pendingMessageID = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPendingMessageCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.body forKey:@"body"];
	[coder encodeObject:self.pendingMessageID forKey:@"pendingMessageID"];
	[coder encodeDouble:self.creationTime forKey:@"creationTime"];
}

- (NSDictionary *)apiJSON {
	NSNumber *d = [NSNumber numberWithDouble:self.creationTime];
	return @{@"message":@{@"nonce":self.pendingMessageID, @"body":self.body, @"client_created_at":d}};
}
@end
