//
//  ATPerson.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPerson.h"

#define kATPersonCodingVersion 1

@implementation ATPerson
@synthesize apptentiveID;
@synthesize name;
@synthesize facebookID;
@synthesize emailAddress;


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		self.name = (NSString *)[coder decodeObjectForKey:@"name"];
		self.facebookID = (NSString *)[coder decodeObjectForKey:@"facebookID"];
		self.emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
	}
	return self;
}

- (void)dealloc {
	[apptentiveID release], apptentiveID = nil;
	[name release], name = nil;
	[facebookID release], facebookID = nil;
	[emailAddress release], emailAddress = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.facebookID forKey:@"facebookID"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
}

+ (ATPerson *)newPersonFromJSON:(NSDictionary *)json {
	ATPerson *result = nil;
	BOOL success = NO;
	
	do { // once
		if (!json) break;
		NSObject *tmp = [json objectForKey:@"person"];
		if (!tmp || ![tmp isKindOfClass:[NSDictionary class]]) break;
		NSDictionary *p = (NSDictionary *)tmp;
		
		result = [[ATPerson alloc] init];
		result.apptentiveID = [p objectForKey:@"id"];
		result.name = [p objectForKey:@"name"];
		result.facebookID = [p objectForKey:@"facebook_id"];
		result.emailAddress = [p objectForKey:@"primary_email"];
		
		success = YES;
	} while (NO);
	
	if (result != nil && success == NO) {
		[result release], result = nil;
	}
	
	
	return result;
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.apptentiveID) {
		[result setObject:self.apptentiveID forKey:@"id"];
	}
	if (self.name) {
		[result setObject:self.name forKey:@"name"];
	}
	if (self.facebookID) {
		[result setObject:self.facebookID forKey:@"facebook_id"];
	}
	if (self.emailAddress) {
		[result setObject:self.emailAddress forKey:@"primary_email"];
	}
	
	return [NSDictionary dictionaryWithObject:result forKey:@"person"];
}
@end
