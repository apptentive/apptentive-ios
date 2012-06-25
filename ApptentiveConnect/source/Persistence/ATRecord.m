//
//  ATRecord.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATRecord.h"
#import "ATConnect.h"
#import "ATBackend.h"
#import "ATUtilities.h"

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

#define kRecordCodingVersion 1

@implementation ATRecord
@synthesize uuid, model, os_version, carrier, date;
- (id)init {
	if ((self = [super init])) {
		self.uuid = [[ATBackend sharedBackend] deviceUUID];
#if TARGET_OS_IPHONE
		self.model = [[UIDevice currentDevice] model];
		self.os_version = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
		if ([CTTelephonyNetworkInfo class]) {
			CTTelephonyNetworkInfo *netInfo = [[CTTelephonyNetworkInfo alloc] init];
			CTCarrier *c = [netInfo subscriberCellularProvider];
			if (c.carrierName) {
				self.carrier = c.carrierName;
			}
			[netInfo release];
		}
#elif TARGET_OS_MAC
		self.model = [ATUtilities currentMachineName];
		self.os_version = [NSString stringWithFormat:@"%@ %@", [ATUtilities currentSystemName], [ATUtilities currentSystemVersion]];
		self.carrier = @"";
#endif
		self.date = [NSDate date];
	}
	return self;
}

- (void)dealloc {
	[uuid release], uuid = nil;
	[model release], model = nil;
	[os_version release], os_version = nil;
	[carrier release], carrier = nil;
	[date release], date = nil;
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [self init])) {
		int version = 0;
		BOOL hasVersion = YES;
		if ([coder containsValueForKey:@"record_version"]) {
			version = [coder decodeIntForKey:@"record_version"];
		} else {
			version = [coder decodeIntForKey:@"version"];
			hasVersion = NO;
		}
		if ((hasVersion == NO && (version == 1 || version == 2)) || hasVersion == YES) {
			self.uuid = [coder decodeObjectForKey:@"uuid"];
			self.model = [coder decodeObjectForKey:@"model"];
			self.os_version = [coder decodeObjectForKey:@"os_version"];
			self.carrier = [coder decodeObjectForKey:@"carrier"];
			if ([coder containsValueForKey:@"date"]) {
				self.date = [coder decodeObjectForKey:@"date"];
			}
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kRecordCodingVersion forKey:@"record_version"];
	[coder encodeObject:self.uuid forKey:@"uuid"];
	[coder encodeObject:self.model forKey:@"model"];
	[coder encodeObject:self.os_version forKey:@"os_version"];
	[coder encodeObject:self.carrier forKey:@"carrier"];
	[coder encodeObject:self.date forKey:@"date"];
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	NSMutableDictionary *record = [NSMutableDictionary dictionary];
	NSMutableDictionary *device = [NSMutableDictionary dictionary];
	if (self.uuid) [device setObject:self.uuid forKey:@"uuid"];
	if (self.model) [device setObject:self.model forKey:@"model"];
	if (self.os_version) [device setObject:self.os_version forKey:@"os_version"];
	if (self.carrier) [device setObject:self.carrier forKey:@"carrier"];
	
	[record setObject:device forKey:@"device"];
	
	[record setObject:[self formattedDate:self.date] forKey:@"date"];
	
	// Add some client information.
	NSMutableDictionary *client = [NSMutableDictionary dictionary];
	[client setObject:kATConnectVersionString forKey:@"version"];
	[client setObject:kATConnectPlatformString forKey:@"os"];
	[client setObject:@"Apptentive, Inc." forKey:@"author"];
	[record setObject:client forKey:@"client"];
	[d setObject:record forKey:@"record"];
	return d;	
}

- (NSDictionary *)apiDictionary {
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	if (self.uuid) [d setObject:self.uuid forKey:@"record[device][uuid]"];
	if (self.model) [d setObject:self.model forKey:@"record[device][model]"];
	if (self.os_version) [d setObject:self.os_version forKey:@"record[device][os_version]"];
	if (self.carrier) [d setObject:self.carrier forKey:@"record[device][carrier]"];
	
	[d setObject:[self formattedDate:self.date] forKey:@"record[date]"];
	
	// Add some client information.
	[d setObject:kATConnectVersionString forKey:@"record[client][version]"];
	[d setObject:kATConnectPlatformString forKey:@"record[client][os]"];
	[d setObject:@"Apptentive, Inc." forKey:@"record[client][author]"];
	return d;
}

- (NSString *)formattedDate:(NSDate *)aDate {
	return [ATUtilities stringRepresentationOfDate:aDate];
}

- (ATAPIRequest *)requestForSendingRecord {
	return nil;
}
@end
