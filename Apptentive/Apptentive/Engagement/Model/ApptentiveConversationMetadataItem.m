//
//  ApptentiveConversationMetadataItem.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationMetadataItem.h"

#define VERSION 1

static NSString *const StateKey = @"state";
static NSString *const UserIdentifierKey = @"userIdentifier";
static NSString *const KeyIdentifierKey = @"keyIdentifier";
static NSString *const FileNameKey = @"fileName";
static NSString *const VersionKey = @"version";

@implementation ApptentiveConversationMetadataItem

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_state = [coder decodeIntegerForKey:StateKey];
		_userIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:UserIdentifierKey];
		_keyIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:KeyIdentifierKey];
		_fileName = [coder decodeObjectOfClass:[NSString class] forKey:FileNameKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInteger:self.state forKey:StateKey];
	[coder encodeObject:self.userIdentifier forKey:UserIdentifierKey];
	[coder encodeObject:self.keyIdentifier forKey:KeyIdentifierKey];
	[coder encodeObject:self.fileName forKey:FileNameKey];
	[coder encodeInteger:VERSION forKey:VersionKey];
}

- (BOOL)isActive {
	return self.state == ApptentiveConversationStateActive;
}

- (BOOL)isDefault {
	return self.state == ApptentiveConversationStateDefault;
}

@end
