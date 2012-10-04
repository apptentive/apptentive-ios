//
//  ATMessage.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessage.h"

#import "ATBackend.h"

#define kATMessageCodingVersion 1

@implementation ATMessage
@synthesize messageType;
@synthesize apptentiveID;
@synthesize creationTime;
@synthesize senderID;
@synthesize recipientID;
@synthesize priority;
@synthesize displayTypes;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.messageType = [coder decodeIntForKey:@"messageType"];
		self.apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		self.creationTime = [(NSNumber *)[coder decodeObjectForKey:@"creationTime"] doubleValue];
		self.senderID = (NSString *)[coder decodeObjectForKey:@"senderID"];
		self.recipientID = (NSString *)[coder decodeObjectForKey:@"recipientID"];
		self.priority = (NSNumber *)[coder decodeObjectForKey:@"priority"];
		@synchronized(self) {
			displayTypes = [(NSArray *)[coder decodeObjectForKey:@"displayTypes"] mutableCopy];
		}
	}
	return self;
}

- (void)dealloc {
	@synchronized(self) {
		[displayTypes release], displayTypes = nil;
	}
	[apptentiveID release], apptentiveID = nil;
	[senderID release], senderID = nil;
	[recipientID release], recipientID = nil;
	[priority release], priority = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATMessageCodingVersion forKey:@"version"];
	
	[coder encodeInt:self.messageType forKey:@"messageType"];
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:[NSNumber numberWithDouble:self.creationTime] forKey:@"creationTime"];
	[coder encodeObject:self.senderID forKey:@"senderID"];
	[coder encodeObject:self.recipientID forKey:@"recipientID"];
	[coder encodeObject:self.priority forKey:@"priority"];
	@synchronized(self) {
		[coder encodeObject:self.displayTypes forKey:@"displayTypes"];
	}
}

- (NSArray *)displayTypes {
	NSArray *result = nil;
	@synchronized(self) {
		result = [NSArray arrayWithArray:displayTypes];
	}
	return result;
}

- (BOOL)isOfMessageDisplayType:(ATMessageDisplayType)typeToCheck {
	BOOL result = NO;
	@synchronized(self) {
		for (NSNumber *typeNumber in displayTypes) {
			ATMessageDisplayType displayType = [typeNumber intValue];
			if (displayType == typeToCheck) {
				result = YES;
				break;
			}
		}
	}
	return result;
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.apptentiveID) {
		[result setObject:self.apptentiveID forKey:@"id"];
	}
	if (self.creationTime != 0) {
		[result setObject:[NSNumber numberWithDouble:self.creationTime] forKey:@"created_at"];
	}
	if (self.senderID) {
		[result setObject:self.senderID forKey:@"sender_id"];
	}
	
	[result setObject:[[ATBackend sharedBackend] deviceUUID] forKey:@"device_id"];
	
	return [NSDictionary dictionaryWithObject:result forKey:@"message"];
}
@end
