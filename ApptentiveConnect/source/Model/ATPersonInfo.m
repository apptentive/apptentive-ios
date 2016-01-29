//
//  ATPersonInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonInfo.h"

#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"
#import "ATPersonUpdater.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"

#define kATPersonCodingVersion 1

@implementation ATPersonInfo

+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json {
	if (json == nil) {
		return nil;
	} else {
		return [[ATPersonInfo alloc] initWithJSONDictionary:json];
	}
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];

	if (self) {
		_apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		_name = (NSString *)[coder decodeObjectForKey:@"name"];
		_emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];

	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];

	[super encodeWithCoder:coder];
}

- (instancetype)initWithJSONDictionary:(NSDictionary *)json {
	self = [super initWithJSONDictionary:json];

	if (self) {
		_apptentiveID = [json at_safeObjectForKey:@"id"];
		_name = [json at_safeObjectForKey:@"name"];
		_emailAddress = [json at_safeObjectForKey:@"email"];
	}

	return self;
}

- (void)setName:(NSString *)name {
	_name = name;
	[self saveAndFlagForUpdate];
}

- (void)setEmailAddress:(NSString *)emailAddress {
	_emailAddress = emailAddress;
	[self saveAndFlagForUpdate];
}

#pragma mark - Persistence

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *person = [super.dictionaryRepresentation mutableCopy];

	if (self.name) {
		[person setObject:self.name forKey:@"name"];
	}

	if (self.emailAddress && [self.emailAddress length] > 0 && [ATUtilities emailAddressIsValid:self.emailAddress]) {
		[person setObject:self.emailAddress forKey:@"email"];
	} else if ([[self.emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		// Delete a previously entered email
		[person setObject:[NSNull null] forKey:@"email"];
	}

	return @{ @"person": person };
}

//- (NSDictionary *)apiJSON {
//	return [ATUtilities diffDictionary:self.dictionaryRepresentation againstDictionary:[ATPersonUpdater lastSavedVersion]];
//}

@end
