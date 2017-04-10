//
//  ApptentiveMessageSender.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/22/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageSender.h"

static NSString *const NameKey = @"name";
static NSString *const IdentifierKey = @"identifier";
static NSString *const ProfilePhotoURLKey = @"profilePhotoURL";


@implementation ApptentiveMessageSender

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithJSON:(NSDictionary *)JSON {
	self = [super init];

	if (self) {
		if (![JSON isKindOfClass:[NSDictionary class]]) {
			return nil;
		}

		_name = JSON[@"name"];
		_identifier = JSON[@"id"];

		NSString *profilePhotoURLString = JSON[@"profile_photo"];
		if ([profilePhotoURLString isKindOfClass:[NSString class]]) {
			_profilePhotoURL = [NSURL URLWithString:profilePhotoURLString];
		}
	}

	return self;
}

- (instancetype)initWithName:(NSString *)name identifier:(NSString *)identifier profilePhotoURL:(NSURL *)profilePhotoURL {
	self = [super init];

	if (self) {
		_name = name;
		_identifier = identifier;
		_profilePhotoURL = profilePhotoURL;
	}

	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
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
