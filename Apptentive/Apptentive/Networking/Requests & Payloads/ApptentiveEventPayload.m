//
//  ApptentiveEventPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveEventPayload.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveEventPayload

- (nullable instancetype)initWithLabel:(NSString *)label creationDate:(NSDate *)creationDate {
	self = [super initWithCreationDate:creationDate];

	if (self) {
		if (label.length == 0) {
			ApptentiveLogError(@"Event label is nil");
			return nil;
		}

		_label = label;
	}

	return self;
}

- (NSString *)type {
	return @"event";
}

- (NSString *)path {
	return @"conversations/<cid>/events";
}

- (NSString *)containerName {
	return @"event";
}

- (NSDictionary *)contents {
	NSMutableDictionary *contents = [super.contents mutableCopy];

	contents[@"label"] = self.label;

	if (self.interactionIdentifier != nil) {
		contents[@"interaction_id"] = self.interactionIdentifier;
	}

	if (self.userInfo != nil) {
		contents[@"data"] = self.userInfo;
	}

	if (self.customData) {
		NSDictionary *customDataDictionary = @{ @"custom_data": self.customData };
		if ([NSJSONSerialization isValidJSONObject:customDataDictionary]) {
			[contents addEntriesFromDictionary:customDataDictionary];
		} else {
			ApptentiveLogError(@"Event `customData` cannot be transformed into valid JSON and will be ignored.");
			ApptentiveLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
		}
	}

	if (self.extendedData) {
		for (NSDictionary *data in self.extendedData) {
			if ([NSJSONSerialization isValidJSONObject:data]) {
				// Extended data items are not added for key "extended_data", but rather for key of extended data type: "time", "location", etc.
				[contents addEntriesFromDictionary:data];
			} else {
				ApptentiveLogError(@"Event `extendedData` cannot be transformed into valid JSON and will be ignored.");
				ApptentiveLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
			}
		}
	}

	return contents;
}

@end

NS_ASSUME_NONNULL_END
