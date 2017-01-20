//
//  ApptentivePerson.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveCustomData.h"

@class ApptentiveMutablePerson;


/**
 An `ApptentivePerson` object represents a person using the Apptentive SDK.
 */
@interface ApptentivePerson : ApptentiveCustomData

/**
 The name associated with the person.
 */
@property (readonly, strong, nonatomic) NSString *name;

/**
 The email address associated with the person.
 */
@property (readonly, strong, nonatomic) NSString *emailAddress;

/**
 Initializes an immutable person object based on the specified mutable object.

 @param mutablePerson The mutable person object whose values should be copied.
 @return The newly-initialized immutable copy.
 
 TODO: Make this a `copy` method on `ApptentiveMutablePerson`?
 */
- (instancetype)initWithMutablePerson:(ApptentiveMutablePerson *)mutablePerson;

@end
