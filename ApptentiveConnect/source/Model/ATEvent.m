//
//  ATEvent.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATEvent.h"


@implementation ATEvent

@dynamic dictionaryData;
@dynamic label;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
}

- (NSDictionary *)apiJSON {
	NSDictionary *parentJSON = [super apiJSON];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (parentJSON) {
		[result addEntriesFromDictionary:parentJSON];
	}
	if (self.label != nil) {
		result[@"label"] = self.label;
	}
	if (self.dictionaryData) {
		NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:self.dictionaryData];
		result[@"data"] = dictionary;
	}
	return @{@"event":result};
}

- (void)setup {
	if ([self isClientCreationTimeEmpty]) {
		[self updateClientCreationTime];
	}
}
@end
