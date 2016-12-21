//
//  ApptentivePerson.h
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableDeviceState.h"

@class ApptentivePersonState;

@interface ApptentiveMutablePersonState : ApptentiveMutableDeviceState

- (instancetype)initWithPersonState:(ApptentivePersonState *)state;

@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *emailAddress;

@end
