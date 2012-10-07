//
//  ATDeviceInfo.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/6/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceInfo.h"

#import "ATConnect.h"

@implementation ATDeviceInfo
- (id)init {
	if ((self = [super init])) {
		record = [[ATRecord alloc] init];
	}
	return self;
}

- (void)dealloc {
	[record release], record = nil;
	[super dealloc];
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	NSMutableDictionary *device = [NSMutableDictionary dictionary];
	
	[device setObject:kATConnectPlatformString forKey:@"os_name"];
	if (record.os_version) [device setObject:record.os_version forKey:@"os_version"];
	if (record.model) [device setObject:record.model forKey:@"model"];
	if (record.uuid) [device setObject:record.uuid forKey:@"uuid"];
	if (record.carrier) [device setObject:record.carrier forKey:@"carrier"];
	
	[d setObject:device forKey:@"device"];
	
	return d;
}
@end
