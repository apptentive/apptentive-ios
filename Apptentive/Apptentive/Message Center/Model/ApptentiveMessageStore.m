//
//  ApptentiveMessageStore.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/3/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageStore.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const MessagesKey = @"messages";
static NSString *const LastMessageIdentifierKey = @"lastMessageIdentifier";
static NSString *const ArchiveVersionKey = @"archiveVersion";


@implementation ApptentiveMessageStore

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_messages = [NSMutableArray array];
	}
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];
	if (self) {
		_messages = [coder decodeObjectOfClass:[NSMutableArray class] forKey:MessagesKey];
		_lastMessageIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:LastMessageIdentifierKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.messages forKey:MessagesKey];
	[coder encodeObject:self.lastMessageIdentifier forKey:LastMessageIdentifierKey];
	[coder encodeObject:@1 forKey:ArchiveVersionKey];
}

@end

NS_ASSUME_NONNULL_END
