//
//  ApptentiveSafeCollections.h
//  Apptentive
//
//  Created by Alex Lementuev on 3/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Returns non-nil value or NSNull
 */
id ApptentiveCollectionValue(id value);

/**
 Safely adds key and value into the dictionary
 */
void ApptentiveDictionarySetKeyValue(NSMutableDictionary *dictionary, id<NSCopying> key, id value);

/**
 Tries to add nullable value into the dictionary
 */
BOOL ApptentiveDictionaryTrySetKeyValue(NSMutableDictionary *dictionary, id<NSCopying> key, id value);

/**
 Safely retrieves BOOL from a dictionary (or returns NO if failed)
 */
BOOL ApptentiveDictionaryGetBool(NSDictionary *dictionary, id<NSCopying> key);

/**
 Safely retrieves string from a dictionary (or returns nil if failed)
 */
NSString *_Nullable ApptentiveDictionaryGetString(NSDictionary *dictionary, id<NSCopying> key);

/**
 Safely retrieves array from a dictionary (or returns nil if failed)
 */
NSArray *_Nullable ApptentiveDictionaryGetArray(NSDictionary *dictionary, id<NSCopying> key);

/**
 Safely adds an object to the array.
 */
void ApptentiveArrayAddObject(NSMutableArray *array, id object);

NS_ASSUME_NONNULL_END
