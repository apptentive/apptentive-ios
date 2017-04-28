//
//  ApptentiveDevicePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDevicePayload.h"


@implementation ApptentiveDevicePayload

- (instancetype)initWithDeviceDiffs:(NSDictionary *)deviceDiffs {
	self = [super init];

	if (self) {
		_deviceDiffs = deviceDiffs;
	}

	return self;
}

- (NSString *)path {
	return @"conversations/<cid>/device";
}

- (NSString *)method {
	return @"PUT";
}

- (NSString *)containerName {
	return @"device";
}

@end
