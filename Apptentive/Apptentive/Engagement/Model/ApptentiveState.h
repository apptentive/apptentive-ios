//
//  ApptentiveState.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `ApptentiveState` is an abstract class that represents a piece of user state
 in the Apptentive SDK. 
 */
@interface ApptentiveState : NSObject <NSSecureCoding>

@end


/**
 The `JSON` category on `ApptentiveState` defines a number of methods that
 streamline JSON encoding of an object. Most subclasses will only have to 
 implement `JSONKeyPathMapping`.
 */
@interface ApptentiveState (JSON)

/**
 Defines a mapping between JSON keys and object key paths.

 @return A dictionary whose keys are the JSON keys used when encoding the
 object, and whose values are key paths used for reading those values from the
 object.
 */
+ (NSDictionary *)JSONKeyPathMapping;

/**
 Returns a representation of the object suitable for JSON encoding.

 @return An dictionary representing the object that can be encoded as JSON.
 */
- (NSDictionary *)JSONDictionary;

@end


/**
 The `Migration` category on `ApptentiveState` defines a method to migrate
 data from versions 3.4 and prior to the current data format, as well as a
 method to clear the data from the old format.
 */
@interface ApptentiveState (Migration)

/**
 Initializes the object with data migrated from, typically, `NSUserDefaults`.
 
 Subclasses should implement this in such a way that data stored in older 
 (<= 3.4.x) versions of the SDK is migrated to the current format.

 @return A newly initialized object read from the migrated data store.
 */
- (instancetype)initAndMigrate;


/**
 Deletes the data migrated from, typically, `NSUserDefaults`. 
 
 Subclasses should implement this in such a way that data stored in older
 (<= 3.4.x) versions of the SDK is removed.
 */
+ (void)deleteMigratedData;

@end

NS_ASSUME_NONNULL_END
