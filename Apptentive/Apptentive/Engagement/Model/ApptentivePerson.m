//
//  ApptentivePerson.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePerson.h"
#import "ApptentiveUnarchiver.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const NameKey = @"name";
static NSString *const EmailAddressKey = @"emailAddress";
static NSString *const MParticleIdKey = @"mParticleId";

// Legacy keys
NSString *const ATPersonLastUpdateValuePreferenceKey = @"ATPersonLastUpdateValuePreferenceKey";
static NSString *const ATCurrentPersonPreferenceKey = @"ATCurrentPersonPreferenceKey";
static NSString *const ApptentiveCustomPersonDataPreferenceKey = @"ApptentiveCustomPersonDataPreferenceKey";


@implementation ApptentivePerson

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];

	if (self) {
		_name = [aDecoder decodeObjectOfClass:[NSString class] forKey:NameKey];
		_emailAddress = [aDecoder decodeObjectOfClass:[NSString class] forKey:EmailAddressKey];
		_mParticleId = [aDecoder decodeObjectOfClass:[NSString class] forKey:MParticleIdKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject:self.name forKey:NameKey];
	[aCoder encodeObject:self.emailAddress forKey:EmailAddressKey];
	[aCoder encodeObject:self.mParticleId forKey:MParticleIdKey];
}

- (instancetype)initAndMigrate {
	NSData *personData = [[NSUserDefaults standardUserDefaults] objectForKey:ATCurrentPersonPreferenceKey];
	NSString *name;
	NSString *emailAddress;
	NSDictionary *customData;

	if (personData) {
		[NSKeyedUnarchiver setClass:[ApptentiveLegacyPerson class] forClassName:@"ApptentivePersonInfo"];
		[NSKeyedUnarchiver setClass:[ApptentiveLegacyPerson class] forClassName:@"ATPersonInfo"];

		ApptentiveLegacyPerson *person = [ApptentiveUnarchiver unarchivedObjectOfClass:[ApptentiveLegacyPerson class] fromData:personData];

		name = person.name;
		emailAddress = person.emailAddress;
	}

	customData = [[NSUserDefaults standardUserDefaults] objectForKey:ApptentiveCustomPersonDataPreferenceKey];

	// If custom data was stored in a version where custom data persistence was broken, look in the last update value
	if (customData == nil) {
		NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

		if (data) {
			NSSet *allowedClasses = [NSSet setWithArray:@[[NSDictionary class], [NSString class]]];
			NSDictionary *person = [[ApptentiveUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:data] valueForKey:@"person"];
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

+ (NSArray *)sensitiveKeys {
	return [super.sensitiveKeys arrayByAddingObjectsFromArray:@[@"name", @"email", @"mParticleId"]];
}

@end


@implementation ApptentivePerson (JSON)

+ (NSDictionary *)JSONKeyPathMapping {
	return @{
		@"custom_data": NSStringFromSelector(@selector(customData)),
		@"email": NSStringFromSelector(@selector(emailAddress)),
		@"name": NSStringFromSelector(@selector(name)),
		@"mparticle_id": NSStringFromSelector(@selector(mParticleId))
	};
}

@end


@implementation ApptentiveLegacyPerson

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		self.name = (NSString *)[coder decodeObjectOfClass:[NSString class] forKey:@"name"];
		self.emailAddress = (NSString *)[coder decodeObjectOfClass:[NSString class] forKey:@"emailAddress"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    ApptentiveAssertFail(@"We only ever decode this object, not encode it.");
}

@end

@implementation ApptentivePerson (Criteria)

- (nullable NSObject *)valueForFieldWithPath:(NSString *)path {
	if ([path isEqualToString:@"name"]) {
		return self.name;
	} else if ([path isEqualToString:@"email"]) {
		return self.emailAddress;
	} else {
		return [super valueForFieldWithPath:path];
	}
}

- (NSString *)descriptionForFieldWithPath:(NSString *)path {
	if ([path isEqualToString:@"name"]) {
		return @"person name";
	} else if ([path isEqualToString:@"email"]) {
		return @"person email";
	} else {
		NSArray *parts = [path componentsSeparatedByString:@"/"];
		if (parts.count != 2 || ![parts[0] isEqualToString:@"custom_data"]) {
			return [NSString stringWithFormat:@"Unrecognized person field %@", path];
		}

		return [NSString stringWithFormat:@"person_data[%@]", parts[1]];
	}
}

@end


NS_ASSUME_NONNULL_END
