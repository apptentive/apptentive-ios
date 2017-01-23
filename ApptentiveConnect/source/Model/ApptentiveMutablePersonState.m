//
//  ApptentivePerson.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutablePersonState.h"
#import "ApptentivePersonState.h"


@implementation ApptentiveMutablePersonState

- (instancetype)initWithPersonState:(ApptentivePersonState *)state {
	self = [super initWithCustomDataState:state];

	if (self) {
		_name = state.name;
		_emailAddress = state.emailAddress;
	}

	return self;
}

@end
