//
//  ApptentiveMutableCustomData.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 12/21/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ApptentiveCustomData;


/**
 An `ApptentiveMutableCustomData` object is a mutable version of the custom
 data containers underlying the `ApptentivePerson` and `ApptentiveDevice`
 objects (and their corresponding mutable versions).
 */
@interface ApptentiveMutableCustomData : NSObject


/**
 Initializes a mutable custom data container based on the specified custom data
 container.

 @param customData The custom data container that should be copied
 @return The newly-initialized copy of the custom data container.
 
 TODO: Make this a `mutableCopy` method on `ApptentiveCustomData`?
 */
- (instancetype)initWithCustomData:(ApptentiveCustomData *)customData;

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
- (void)removeCustomValueWithKey:(NSString *)key NS_SWIFT_NAME(remove(withKey:));

/**
 A read-only copy of the custom data.
 */
@property (readonly, copy, nonatomic) NSDictionary *customData;

/**
 A string that identifies the person or device object.
 */
@property (readonly, strong, nonatomic) NSString *identifier;

@end
