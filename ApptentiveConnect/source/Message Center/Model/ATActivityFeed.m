//
//  ATActivityFeed.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATActivityFeed.h"

#define kATActivityFeedCodingVersion 1

@implementation ATActivityFeed
@synthesize token;
@synthesize personID;
@synthesize deviceID;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.token = (NSString *)[coder decodeObjectForKey:@"token"];
		self.personID = (NSString *)[coder decodeObjectForKey:@"personID"];
		self.deviceID = (NSString *)[coder decodeObjectForKey:@"deviceID"];
	}
	return self;
}

- (void)dealloc {
	[token release], token = nil;
	[personID release], personID = nil;
	[deviceID release], deviceID = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATActivityFeedCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	ATActivityFeed *result = nil;
	BOOL success = NO;
	
	do { // once
		if (!json) break;
		NSDictionary *p = json;
		
		result = [[ATActivityFeed alloc] init];
		result.token = [p objectForKey:@"token"];
		result.deviceID = [p objectForKey:@"device_id"];
		
		success = YES;
	} while (NO);
	
	if (result != nil && success == NO) {
		[result release], result = nil;
	}
	
	return result;
}

//TODO: Add support for sending person.
- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.deviceID) {
		NSDictionary *deviceInfo = @{@"id":self.deviceID};
		[result setObject:deviceInfo forKey:@"device"];
	}
	
	return result;
}
@end
