//
//  ApptentiveSurveyResponsePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyResponsePayload.h"


@implementation ApptentiveSurveyResponsePayload

- (instancetype)initWithAnswers:(NSDictionary *)answers identifier:(NSString *)identifier {
	self = [super init];

	if (self) {
		_answers = answers;
		_identifier = identifier;
	}

	return self;
}

- (NSString *)path {
	return [NSString stringWithFormat:@"conversations/<cid>/surveys/%@/respond", self.identifier];
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
