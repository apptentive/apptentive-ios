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
static NSString *const ConversationIdentifierKey = @"conversationIdentifier";
static NSString *const FileNameKey = @"fileName";
static NSString *const EncryptionKeyKey = @"encryptionKey";
static NSString *const VersionKey = @"version";
static NSString *const UserIdKey = @"userId";


@implementation ApptentiveConversationMetadataItem

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier directoryName:(NSString *)filename {
	self = [super init];

	if (self) {
		_conversationIdentifier = conversationIdentifier;
		_directoryName = filename;
	}

	return self;
}

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_state = [coder decodeIntegerForKey:StateKey];
		_conversationIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:ConversationIdentifierKey];
		_directoryName = [coder decodeObjectOfClass:[NSString class] forKey:FileNameKey];
		_encryptionKey = [coder decodeObjectOfClass:[NSData class] forKey:EncryptionKeyKey];
        _userId = [coder decodeObjectOfClass:[NSString class] forKey:UserIdKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInteger:self.state forKey:StateKey];
	[coder encodeObject:self.conversationIdentifier forKey:ConversationIdentifierKey];
	[coder encodeObject:self.directoryName forKey:FileNameKey];
	[coder encodeObject:self.encryptionKey forKey:EncryptionKeyKey];
    [coder encodeObject:self.userId forKey:UserIdKey];
	[coder encodeInteger:VERSION forKey:VersionKey];
}

@end
