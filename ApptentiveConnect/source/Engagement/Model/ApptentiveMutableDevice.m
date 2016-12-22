//
//  ApptentiveCustomData.m
//  Store
//
//  Created by Frank Schmitt on 7/22/16.
//  Copyright © 2016 Apptentive. All rights reserved.
//

#import "ApptentiveMutableDevice.h"
#import "ApptentiveDevice.h"

@implementation ApptentiveMutableDevice

- (instancetype)initWithDevice:(ApptentiveDevice *)device {
	self = [super initWithCustomData:device];

	if (self) {
		_integrationConfiguration = device.integrationConfiguration;
	}

	return self;
}

@end
