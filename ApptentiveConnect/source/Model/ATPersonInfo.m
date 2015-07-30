//
//  ATPerson.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATPersonInfo.h"

#import "ATConnect_Private.h"
#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"
#import "ATPersonUpdater.h"

NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";

#define kATPersonCodingVersion 1

@implementation ATPersonInfo

- (id)init {
	if (self = [super init]) {
		_name = [ATConnect sharedConnection].initialUserName;
		_emailAddress = [ATConnect sharedConnection].initialUserEmailAddress;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		self.apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		self.name = (NSString *)[coder decodeObjectForKey:@"name"];
		self.emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
		self.needsUpdate = [coder decodeBoolForKey:@"needsUpdate"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
	[coder encodeBool:self.needsUpdate forKey:@"needsUpdate"];
}

+ (ATPersonInfo *)currentPerson {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *personData = [defaults dataForKey:ATCurrentPersonPreferenceKey];
	if (!personData) {
		return nil;
	}
	ATPersonInfo *person = nil;
	
	@try {
		person = [NSKeyedUnarchiver unarchiveObjectWithData:personData];
	} @catch (NSException *exception) {
		ATLogError(@"Unable to unarchive person: %@", person);
	}
	
	return person;
}

+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json {
	if (json == nil) {
		return nil;
	}
	
	ATPersonInfo *result = [[ATPersonInfo alloc] init];
	result.apptentiveID = [json at_safeObjectForKey:@"id"];
	result.name = [json at_safeObjectForKey:@"name"];
	result.emailAddress = [json at_safeObjectForKey:@"email"];
	
	return result;
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *person = [NSMutableDictionary dictionary];
	
	if (self.name) {
		[person setObject:self.name forKey:@"name"];
	}
	
	if (self.emailAddress && [self.emailAddress length] > 0 && [ATUtilities emailAddressIsValid:self.emailAddress]) {
		[person setObject:self.emailAddress forKey:@"email"];
	} else if ([[self.emailAddress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
		// Delete a previously entered email
		[person setObject:[NSNull null] forKey:@"email"];
	}
	
	NSDictionary *customPersonData = [[ATConnect sharedConnection] customPersonData] ?: @{};
	[person setObject:customPersonData forKey:@"custom_data"];
	
	return [NSDictionary dictionaryWithObject:person forKey:@"person"];
}

- (NSDictionary *)apiJSON {
	return [ATUtilities diffDictionary:self.dictionaryRepresentation againstDictionary:[ATPersonUpdater lastSavedVersion]];
}

- (NSDictionary *)comparisonDictionary {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	if (self.apptentiveID) {
		[result setObject:self.apptentiveID forKey:@"apptentive_id"];
	}
	if (self.name) {
		[result setObject:self.name forKey:@"name"];
	}
	if (self.emailAddress) {
		[result setObject:self.emailAddress forKey:@"email"];
	}
	
	return result;
}

- (NSUInteger)hash {
	NSString *hashString = [NSString stringWithFormat:@"%@,%@,%@,%@,%@", self.apptentiveID, self.name, self.facebookID, self.emailAddress, self.secret];
	return [hashString hash];
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[ATPersonInfo class]]) {
		return NO;
	}
	ATPersonInfo *other = (ATPersonInfo *)object;
	BOOL equal = [ATUtilities dictionary:[self comparisonDictionary] isEqualToDictionary:[other comparisonDictionary]];
	return equal;
}

- (void)saveAsCurrentPerson {
	ATPersonInfo *currentPerson = [ATPersonInfo currentPerson];
	BOOL isDirty = ![self isEqual:currentPerson];
	if (isDirty || self.needsUpdate != currentPerson.needsUpdate) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSData *personData = [NSKeyedArchiver archivedDataWithRootObject:self];
		[defaults setObject:personData forKey:ATCurrentPersonPreferenceKey];
		if (!currentPerson || !currentPerson.apptentiveID) {
			[defaults synchronize];
		}
	}
}

}

@end
