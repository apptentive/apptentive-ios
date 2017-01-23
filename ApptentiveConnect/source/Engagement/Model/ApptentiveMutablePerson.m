//
//  ApptentivePerson.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutablePerson.h"
#import "ApptentivePerson.h"


@implementation ApptentiveMutablePerson

- (instancetype)initWithPerson:(ApptentivePerson *)person {
	self = [super initWithCustomData:person];

	if (self) {
		_name = person.name;
		_emailAddress = person.emailAddress;
	}

	return self;
}

@end
