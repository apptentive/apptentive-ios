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
static NSString *const VersionKey = @"version";

@implementation ApptentiveConversationMetadataItem

- (instancetype)initWithConversationIdentifier:(NSString *)conversationIdentifier filename:(NSString *)filename {
	self = [super init];

	if (self) {
		_conversationIdentifier = conversationIdentifier;
		_fileName = filename;
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
		_fileName = [coder decodeObjectOfClass:[NSString class] forKey:FileNameKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInteger:self.state forKey:StateKey];
	[coder encodeObject:self.conversationIdentifier forKey:ConversationIdentifierKey];
	[coder encodeObject:self.fileName forKey:FileNameKey];
	[coder encodeInteger:VERSION forKey:VersionKey];
}

@end
