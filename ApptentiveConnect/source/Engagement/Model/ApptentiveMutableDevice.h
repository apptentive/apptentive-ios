//
//  ApptentiveCustomData.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableCustomData.h"

@class ApptentiveDevice, ApptentiveCustomData;


/**
 `ApptentiveMutableDevice` is a version of the `ApptentiveDevice` object
 whose custom data can be modified. It is intended for use
 inside a the block passed to `ApptentiveSession`'s `-updateDevice:` method.
 */
@interface ApptentiveMutableDevice : ApptentiveMutableCustomData

/**
 Initializes a mutable device object based on values in the specified device
 object.

 @param device The device from which to copy custom data.
 @return The newly-intialized mutable copy.
 
 TODO: Make this a `mutableCopy` method on `ApptentiveDevice`?
 */
- (instancetype)initWithDevice:(ApptentiveDevice *)device;

/**
 The integration configuration. See the documentation for `ApptentiveDevice`'s
 `integrationConfiguration` property.
 */
@property (copy, nonatomic) NSDictionary *integrationConfiguration;

@end
