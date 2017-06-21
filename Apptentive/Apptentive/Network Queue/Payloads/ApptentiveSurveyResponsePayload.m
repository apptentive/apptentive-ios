//
//  ApptentiveSurveyResponsePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyResponsePayload.h"


@implementation ApptentiveSurveyResponsePayload

- (nullable instancetype)initWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier {
	if (answers.count == 0) {
		ApptentiveLogError(@"Attempting to create survey response without answers");
		return nil;
	}

	if (identifier.length == 0) {
		ApptentiveLogError(@"Attempting to create survey response without identifier");
		return nil;
	}

	self = [super init];

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
	return @"survey";
}

- (NSDictionary *)contents {
	NSMutableDictionary *contents = [super.contents mutableCopy];

	contents[@"answers"] = self.answers;
	contents[@"id"] = self.identifier;

	return contents;
}

@end
