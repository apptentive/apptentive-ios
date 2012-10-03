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
@synthesize firstName;
@synthesize lastName;
@synthesize facebookID;


- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		self.firstName = (NSString *)[coder decodeObjectForKey:@"firstName"];
		self.lastName = (NSString *)[coder decodeObjectForKey:@"lastName"];
		self.facebookID = (NSString *)[coder decodeObjectForKey:@"facebookID"];
	}
	return self;
}

- (void)dealloc {
	[apptentiveID release], apptentiveID = nil;
	[firstName release], firstName = nil;
	[lastName release], lastName = nil;
	[facebookID release], facebookID = nil;
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.firstName forKey:@"firstName"];
	[coder encodeObject:self.lastName forKey:@"lastName"];
	[coder encodeObject:self.facebookID forKey:@"facebookID"];
}
@end
