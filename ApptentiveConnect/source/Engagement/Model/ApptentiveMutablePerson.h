//
//  ApptentivePerson.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableCustomData.h"

@class ApptentivePerson;


/**
 An `ApptentiveMutablePerson` is a version of the `ApptentivePerson` object
 whose name, email, and custom data can be modified. It is intended for use
 inside a the block passed to `ApptentiveSession`'s `-updatePerson:` method.
 */
@interface ApptentiveMutablePerson : ApptentiveMutableCustomData

/**
 Initializes a mutable person object based on values in the specified person
 object.

 @param person The person from which to copy custom data, name and email.
 @return The newly-initialized mutable copy.
 
 TODO: Make this a `mutableCopy` method on `ApptentivePerson`?
 */
- (instancetype)initWithPerson:(ApptentivePerson *)person;

/**
 The name associated with the person.
 */
@property (readwrite, copy, nonatomic) NSString *name;

/**
 The email address associated with the person.
 */
@property (readwrite, copy, nonatomic) NSString *emailAddress;

@end
