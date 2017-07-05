//
//  ApptentiveConversationMetadata.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationMetadata.h"
#import "ApptentiveConversationMetadataItem.h"
#import "ApptentiveConversation.h"

#define VERSION 1

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

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_items = [coder decodeObjectOfClass:[NSMutableArray class] forKey:ItemsKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.items forKey:ItemsKey];
	[coder encodeInteger:VERSION forKey:VersionKey];
}

- (void)addItem:(ApptentiveConversationMetadataItem *)item {
	ApptentiveAssertNotNil(item, @"Attempting to add nil item to metadata");

	[self.items addObject:item];
}

- (void)deleteItem:(ApptentiveConversationMetadataItem *)item {
	ApptentiveAssertNotNil(item, @"Attempting to remove nil item from metadata");

	[self.items removeObject:item];
}

#pragma mark - Filtering

- (ApptentiveConversationMetadataItem *)findItemFilter:(ApptentiveConversationMetadataItemFilter)filter {
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

@end