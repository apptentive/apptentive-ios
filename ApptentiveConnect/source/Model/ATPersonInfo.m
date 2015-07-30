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

+ (ATPersonInfo *)currentPerson {
	static ATPersonInfo *_currentPerson;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSData *personData = [[NSUserDefaults standardUserDefaults] dataForKey:ATCurrentPersonPreferenceKey];
		
		if (personData) {
			@try {
				_currentPerson = [NSKeyedUnarchiver unarchiveObjectWithData:personData];
			} @catch (NSException *exception) {
				ATLogError(@"Unable to unarchive person: %@", personData);
			}
		} else {
			_currentPerson = [[ATPersonInfo alloc] init];
		}
	});
	
	return _currentPerson;
}

+ (ATPersonInfo *)newPersonFromJSON:(NSDictionary *)json {
	if (json == nil) {
		return nil;
	} else {
		return [[ATPersonInfo alloc] initWithJSONDictionary:json];
	}
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];
	
	if (self) {
		_apptentiveID = (NSString *)[coder decodeObjectForKey:@"apptentiveID"];
		_name = (NSString *)[coder decodeObjectForKey:@"name"];
		_emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
		
		[self commonInit];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATPersonCodingVersion forKey:@"version"];
	
	[coder encodeObject:self.apptentiveID forKey:@"apptentiveID"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.emailAddress forKey:@"emailAddress"];
}

- (instancetype) initWithJSONDictionary:(NSDictionary *)json {
	self = [super init];
	
	if (self) {
		_apptentiveID = [json at_safeObjectForKey:@"id"];
		_name = [json at_safeObjectForKey:@"name"];
		_emailAddress = [json at_safeObjectForKey:@"email"];
		
		[self commonInit];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Persistence

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
	NSString *hashString = [NSString stringWithFormat:@"%@,%@,%@", self.apptentiveID, self.name, self.emailAddress];
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

#pragma mark - Private

- (void)commonInit {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)save:(NSNotification *)notification {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *personData = [NSKeyedArchiver archivedDataWithRootObject:self];
	
	[defaults setObject:personData forKey:ATCurrentPersonPreferenceKey];
	[defaults synchronize];
}

@end
