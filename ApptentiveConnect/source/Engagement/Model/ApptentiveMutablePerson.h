//
//  ApptentivePerson.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableCustomData.h"

@class ApptentivePerson;

@interface ApptentiveMutablePerson : ApptentiveMutableCustomData

- (instancetype)initWithPerson:(ApptentivePerson *)person;

@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *emailAddress;

@end
