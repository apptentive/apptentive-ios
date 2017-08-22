//
//  ApptentiveSafeCollections.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSafeCollections.h"
#import "ApptentiveAssert.h"

void ApptentiveDictionarySetKeyValue(NSMutableDictionary *dictionary, id<NSCopying> key, id value) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	ApptentiveAssertNotNil(value, @"Value is nil");
	if (key != nil && value != nil) {
		dictionary[key] = value;
	}
}

BOOL ApptentiveDictionaryTrySetKeyValue(NSMutableDictionary *dictionary, id<NSCopying> key, id value) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	if (key != nil && value != nil) {
		dictionary[key] = value;
		return YES;
	}
	return NO;
}

NSString *ApptentiveDictionaryGetString(NSDictionary *dictionary, id<NSCopying> key) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	if (key != nil) {
		id value = dictionary[key];
		return [value isKindOfClass:[NSString class]] ? value : nil;
	}
	return nil;
}

NSArray *ApptentiveDictionaryGetArray(NSDictionary *dictionary, id<NSCopying> key) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	if (key != nil) {
		id value = dictionary[key];
		return [value isKindOfClass:[NSArray class]] ? value : nil;
	}
	return nil;
}

void ApptentiveArrayAddObject(NSMutableArray *array, id object) {
	ApptentiveAssertNotNil(object, @"Object is nil");
	if (object != nil) {
		[array addObject:object];
	}
}
