//
//  ApptentiveArchiver.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/5/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveArchiver.h"

@implementation ApptentiveArchiver

+ (BOOL)archiveRootObject:(NSObject *)rootObject toFile:(NSString *)path {
	NSData *result = [self archivedDataWithRootObject:rootObject];

	if (result != nil) {
		return [result writeToFile:path atomically:YES];
	} else {
		return NO;
	}
}

+ (nullable NSData *)archivedDataWithRootObject:(NSObject *)rootObject {
	NSError *error = nil;
	NSData *result = nil;

	if (@available(iOS 11.0, *)) {
		result = [NSKeyedArchiver archivedDataWithRootObject:rootObject requiringSecureCoding:YES error:&error];
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		result = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
#pragma clang diagnostic pop
	}

	if (result == nil) {
		ApptentiveAssertFail(@"Unable to archive object: %@", error);
		ApptentiveLogError(ApptentiveLogTagUtility, @"Unable to archive object: %@", error);
	}

	return result;
}

@end
