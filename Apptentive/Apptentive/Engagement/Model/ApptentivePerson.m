//
//  ApptentivePerson.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePerson.h"
#import "ApptentiveMutablePerson.h"

static NSString *const NameKey = @"name";
static NSString *const EmailAddressKey = @"emailAddress";

// Legacy keys
static NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";
static NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";
static NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";


@implementation ApptentivePerson

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
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
	NSString *name;
	NSString *emailAddress;
	NSDictionary *customData;

	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

	if (data) {
		NSDictionary *person = [[NSKeyedUnarchiver unarchiveObjectWithData:data] valueForKey:@"person"];
		if ([person isKindOfClass:[NSDictionary class]]) {
			name = person[@"name"];
			emailAddress = person[@"email"];
			customData = person[@"custom_data"];
		}
	}

	self = [super initWithCustomData:customData];

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

- (instancetype)initWithMutablePerson:(ApptentiveMutablePerson *)mutablePerson {
	self = [super initWithMutableCustomData:mutablePerson];

	if (self) {
		_name = mutablePerson.name;
		_emailAddress = mutablePerson.emailAddress;
	}

	return self;
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
