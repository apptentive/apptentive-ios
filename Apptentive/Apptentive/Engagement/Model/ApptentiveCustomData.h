//
//  ApptentiveCustomData.h
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveState.h"

@class ApptentiveMutableCustomData;


/**
 `ApptentiveCustomData` is an abstract base class used by the `ApptentivePerson`
 and `ApptentiveDevice` classes to manage the storage of custom data.
 */
@interface ApptentiveCustomData : ApptentiveState

/**
 The custom data dictionary.
 */
@property (readonly, strong, nonatomic) NSDictionary<NSString *, NSObject<NSCoding> *> *customData;

/**
 An identifier used to identify the person or device.
 */
@property (strong, nonatomic) NSString *identifier;


/**
 Initializes a new custom data container object based on a mutable container
 object.

 @param mutableCustomDataContainer The mutable container object to copy
 @return The newly-initialzed custom data container.
 */
- (instancetype)initWithMutableCustomData:(ApptentiveMutableCustomData *)mutableCustomDataContainer;

/**
 Initializes a new custom data container object with the specified custom data
 dictionary.

 @param customData The custom data dictionary.
 @return The newly-initialzed custom data container.
 */
- (instancetype)initWithCustomData:(NSDictionary *)customData;

@end
