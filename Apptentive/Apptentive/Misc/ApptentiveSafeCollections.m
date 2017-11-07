//
//  ApptentiveSafeCollections.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSafeCollections.h"
#import "ApptentiveAssert.h"

NS_ASSUME_NONNULL_BEGIN

id ApptentiveCollectionValue(id value) {
	ApptentiveAssertNotNil(value, @"Value is nil");
	return value ?: [NSNull null];
}

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

BOOL ApptentiveDictionaryGetBool(NSDictionary *dictionary, id<NSCopying> key) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	if (key != nil) {
		id value = dictionary[key];
		return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
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

NS_ASSUME_NONNULL_END
