//
//  ApptentiveDevicePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDevicePayload.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveDevicePayload

- (instancetype)initWithDeviceDiffs:(NSDictionary *)deviceDiffs {
	self = [super init];

	if (self) {
		_deviceDiffs = deviceDiffs;
	}

	return self;
}

- (NSString *)type {
	return @"device";
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

- (NSDictionary *)contents {
	NSMutableDictionary *contents = [super.contents mutableCopy];
	[contents addEntriesFromDictionary:self.deviceDiffs];

	return contents;
}

@end

NS_ASSUME_NONNULL_END
