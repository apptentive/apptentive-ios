//
//  ApptentiveSurveyResponsePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyResponsePayload.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveSurveyResponsePayload

- (nullable instancetype)initWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier creationDate:(nonnull NSDate *)creationDate {
	if (answers == nil) {
		ApptentiveLogError(@"Attempting to create survey response without answers");
		return nil;
	}

	if (identifier.length == 0) {
		ApptentiveLogError(@"Attempting to create survey response without identifier");
		return nil;
	}

	self = [super initWithCreationDate:creationDate];

	if (self) {
		_answers = answers;
		_identifier = identifier;
	}

	return self;
}

- (NSString *)type {
	return @"survey";
}

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/<cid>/surveys/%@/responses", self.identifier];
}

- (NSString *)containerName {
	return @"response";
}

- (NSDictionary *)contents {
	NSMutableDictionary *contents = [super.contents mutableCopy];

	contents[@"answers"] = self.answers;
	contents[@"id"] = self.identifier;

	return contents;
}

@end

NS_ASSUME_NONNULL_END
