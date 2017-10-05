//
//  ApptentivePerson.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePerson.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const NameKey = @"name";
static NSString *const EmailAddressKey = @"emailAddress";

// Legacy keys
NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";
static NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";
static NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";


@implementation ApptentivePerson

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_name = [aDecoder decodeObjectOfClass:[NSString class] forKey:NameKey];
		_emailAddress = [aDecoder decodeObjectOfClass:[NSString class] forKey:EmailAddressKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:self.name forKey:NameKey];
	[aCoder encodeObject:self.emailAddress forKey:EmailAddressKey];
}

- (instancetype)initAndMigrate {
	NSData *personData = [[NSUserDefaults standardUserDefaults] objectForKey:ATCurrentPersonPreferenceKey];
	NSString *name;
	NSString *emailAddress;
	NSDictionary *customData;

	if (personData) {
		[NSKeyedUnarchiver setClass:[ApptentiveLegacyPerson class] forClassName:@"ApptentivePersonInfo"];
		[NSKeyedUnarchiver setClass:[ApptentiveLegacyPerson class] forClassName:@"ATPersonInfo"];

		ApptentiveLegacyPerson *person = [NSKeyedUnarchiver unarchiveObjectWithData:personData];

		name = person.name;
		emailAddress = person.emailAddress;
	}

	customData = [[NSUserDefaults standardUserDefaults] objectForKey:ApptentiveCustomPersonDataPreferenceKey];

	// If custom data was stored in a version where custom data persistence was broken, look in the last update value
	if (customData == nil) {
		NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

		if (data) {
			NSDictionary *person = [[NSKeyedUnarchiver unarchiveObjectWithData:data] valueForKey:@"person"];
			if ([person isKindOfClass:[NSDictionary class]]) {
				customData = person[@"custom_data"];
			}
		}
	}

	self = [super initWithCustomData:customData ?: @{}];

	if (self) {
		_name = name;
		_emailAddress = emailAddress;
	}

	return self;
}

+ (void)deleteMigratedData {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATPersonLastUpdateValuePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATCurrentPersonPreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ApptentiveCustomPersonDataPreferenceKey];
}

@end


@implementation ApptentivePerson (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"custom_data": NSStringFromSelector(@selector(customData)),
		@"email": NSStringFromSelector(@selector(emailAddress)),
		@"name": NSStringFromSelector(@selector(name))
	};
}

@end


@implementation ApptentiveLegacyPerson

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		self.name = (NSString *)[coder decodeObjectForKey:@"name"];
		self.emailAddress = (NSString *)[coder decodeObjectForKey:@"emailAddress"];
	}

	return self;
}

@end

NS_ASSUME_NONNULL_END
