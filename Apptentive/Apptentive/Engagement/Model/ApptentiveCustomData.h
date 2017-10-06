//
//  ApptentiveCustomData.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

NS_ASSUME_NONNULL_BEGIN


/**
 `ApptentiveCustomData` is an abstract base class used by the `ApptentivePerson`
 and `ApptentiveDevice` classes to manage the storage of custom data.
 */
@interface ApptentiveCustomData : ApptentiveState

/**
 Initializes a new custom data container object with the specified custom data
 dictionary.

 @param customData The custom data dictionary.
 @return The newly-initialzed custom data container.
 */
- (instancetype)initWithCustomData:(NSDictionary *)customData;

/**
 Adds a string to the custom data.
 @param string The string to be added.
 @param key The key corresponding to the string.
 */
- (void)addCustomString:(NSString *)string withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));

/**
 Adds a number to the custom data.
 @param number The number to be added.
 @param key The key corresponding to the number.
 */
- (void)addCustomNumber:(NSNumber *)number withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));

/**
 Adds a boolean value to the custom data.
 @param boolValue The boolean value to add.
 @param key The key corresponding to the boolean value.
 */
- (void)addCustomBool:(BOOL)boolValue withKey:(NSString *)key NS_SWIFT_NAME(add(_:withKey:));

/**
 Removes a value from the custom data.

 @param key The key corresponding to the value.
 */
- (void)removeCustomValueWithKey:(NSString *)key NS_SWIFT_NAME(remove(withKey:));

/**
 A read-only copy of the custom data.
 */
@property (readonly, copy, nonatomic) NSDictionary *customData;

/**
 A string that identifies the person or device object.
 */
@property (strong, nonatomic) NSString *identifier;

@end

NS_ASSUME_NONNULL_END
