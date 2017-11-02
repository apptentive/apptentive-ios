//
//  ApptentiveMessageSender.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageSender.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const NameKey = @"name";
static NSString *const IdentifierKey = @"identifier";
static NSString *const ProfilePhotoURLKey = @"profilePhotoURL";


@implementation ApptentiveMessageSender

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (nullable instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			ApptentiveLogError(@"Can't init %@: invalid json object class: %@", NSStringFromClass([self class]), NSStringFromClass([JSON class]));
			return nil;
		}

		_name = ApptentiveDictionaryGetString(JSON, @"name");

		_identifier = ApptentiveDictionaryGetString(JSON, @"id");
		if (_identifier.length == 0) {
			ApptentiveLogError(@"Can't init %@: identifier is nil or empty", NSStringFromClass([self class]));
			return nil;
		}

		NSString *profilePhotoURLString = ApptentiveDictionaryGetString(JSON, @"profile_photo");
		if (profilePhotoURLString.length > 0) {
			_profilePhotoURL = [NSURL URLWithString:profilePhotoURLString];
		}
	}

	return self;
}

- (nullable instancetype)initWithName:(nullable NSString *)name identifier:(NSString *)identifier profilePhotoURL:(nullable NSURL *)profilePhotoURL {
	self = [super init];

	if (self) {
		if (identifier.length == 0) {
			ApptentiveLogError(@"Can't init %@: identifier is nil or empty", NSStringFromClass([self class]));
			return nil;
		}

		_name = name;
		_identifier = identifier;
		_profilePhotoURL = profilePhotoURL;
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		_name = [coder decodeObjectOfClass:[NSString class] forKey:NameKey];
		_identifier = [coder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
		_profilePhotoURL = [coder decodeObjectOfClass:[NSURL class] forKey:ProfilePhotoURLKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.name forKey:NameKey];
	[coder encodeObject:self.identifier forKey:IdentifierKey];
	[coder encodeObject:self.profilePhotoURL forKey:ProfilePhotoURLKey];
}

@end

NS_ASSUME_NONNULL_END
