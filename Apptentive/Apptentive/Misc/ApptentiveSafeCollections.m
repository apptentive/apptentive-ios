//
//  ApptentiveSafeCollections.m
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSafeCollections.h"
#import "ApptentiveAssert.h"

void ApptentiveDictionarySetKeyValue(NSMutableDictionary *dictionary, NSString *key, id value) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	ApptentiveAssertNotNil(value, @"Value is nil");
	if (key != nil && value != nil) {
		dictionary[key] = value;
	}
}

BOOL ApptentiveDictionaryTrySetKeyValue(NSMutableDictionary *dictionary, NSString *key, id value) {
	ApptentiveAssertNotNil(key, @"Key is nil");
	if (key != nil && value != nil) {
		dictionary[key] = value;
		return YES;
	}
	return NO;
}
