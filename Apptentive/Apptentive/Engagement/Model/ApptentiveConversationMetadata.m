//
//  ApptentiveConversationMetadata.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationMetadata.h"
#import "ApptentiveConversation.h"
#import "ApptentiveConversationMetadataItem.h"
#import "ApptentiveUtilities.h"

#define VERSION 1

NS_ASSUME_NONNULL_BEGIN

static NSString *const ItemsKey = @"items";
static NSString *const VersionKey = @"version";


@implementation ApptentiveConversationMetadata

+ (BOOL)supportsSecureCoding {
	return YES;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_items = [[NSMutableArray alloc] init];
	}

	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_items = [coder decodeObjectOfClass:[NSMutableArray class] forKey:ItemsKey];

		[self checkConsistency];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.items forKey:ItemsKey];
	[coder encodeInteger:VERSION forKey:VersionKey];
}

- (void)addItem:(ApptentiveConversationMetadataItem *)item {
	ApptentiveAssertNotNil(item, @"Attempting to add nil item to metadata");
	ApptentiveArrayAddObject(self.items, item);
}

- (void)deleteItem:(ApptentiveConversationMetadataItem *)item {
	ApptentiveAssertNotNil(item, @"Attempting to remove nil item from metadata");
	if (item) {
		[self.items removeObject:item];
	}
}

#pragma mark - Filtering

- (nullable ApptentiveConversationMetadataItem *)findItemFilter:(ApptentiveConversationMetadataItemFilter)filter {
	// TODO: ApptentiveAssertNotNull(filter);
	if (filter != nil) {
		for (id item in _items) {
			if (filter(item)) {
				return item;
			}
		}
	}
	return nil;
}

#pragma mark - Debug

- (void)printAsTableWithTitle:(NSString *)title {
	if (!ApptentiveCanLogLevel(ApptentiveLogLevelVerbose)) {
		return;
	}

	NSMutableArray *items = _items;

	if (items.count == 0) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"%@ (%ld item(s))", title, items.count);
		return;
	}

	NSMutableArray *rows = [NSMutableArray new];
	[rows addObject:@[
		@"state",
		@"localIdentifier",
		@"identifier",
		@"userId",
		@"directoryName",
		@"JWT",
		@"encryptionKey"
	]];

	NSMutableString *moreInfo = [NSMutableString new];

	NSInteger row = 1;
	for (ApptentiveConversationMetadataItem *item in items) {
		if (item.JWT) {
			if (moreInfo.length > 0) {
				[moreInfo appendString:@"\n"];
			}
			[moreInfo appendFormat:@"JWT-%ld: %@", (unsigned long)row, item.JWT];
		}
		if (item.encryptionKey) {
			if (moreInfo.length > 0) {
				[moreInfo appendString:@"\n"];
			}
			[moreInfo appendFormat:@"KEY-%ld: %@", (unsigned long)row, item.encryptionKey];
		}

		[rows addObject:@[
			NSStringFromApptentiveConversationState(item.state),
			item.conversationLocalIdentifier ?: @"nil",
			item.conversationIdentifier ?: @"nil",
			item.userId ?: @"nil",
			item.directoryName ?: @"nil",
			item.JWT ? [NSString stringWithFormat:@"JWT-%ld", (unsigned long)row] : @"nil",
			item.encryptionKey ? [NSString stringWithFormat:@"KEY-%ld", (unsigned long)row] : @"nil"
		]];

		++row;
	}

	NSString *table = [ApptentiveUtilities formatAsTableRows:rows];
	ApptentiveLogVerbose(ApptentiveLogTagConversation, @"%@ (%ld item(s))\n%@\n%@\n-", title, (unsigned long)items.count, table, moreInfo);
}

#pragma mark - Private

- (void)checkConsistency {
	NSMutableArray *invalidItems = [NSMutableArray array];

	for (ApptentiveConversationMetadataItem *item in self.items) {
		if (!item.consistent) {
			ApptentiveLogError(@"Conversation metadata item %@ is inconsistent. Deleting it...", item);

			[invalidItems addObject:item];
		}
	}

	[self.items removeObjectsInArray:invalidItems];
}

@end

NS_ASSUME_NONNULL_END
