//
//  ATRecord.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/13/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATRecord.h"

#import "NSDictionary+ATAdditions.h"

@implementation ATRecord

@dynamic apptentiveID;
@dynamic clientCreationTime;
@dynamic clientCreationTimezone;
@dynamic clientCreationUTCOffset;


+ (NSTimeInterval)timeIntervalForServerTime:(NSNumber *)timestamp {
	long long serverTimestamp = [timestamp longLongValue];
	NSTimeInterval clientTimestamp = ((double)serverTimestamp)/1000.0;
	return clientTimestamp;
}

+ (NSNumber *)serverFormatForTimeInterval:(NSTimeInterval)timestamp {
	return @((long long)(timestamp * 1000));
}


+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tmpID = [json at_safeObjectForKey:@"id"];
	if (tmpID != nil) {
		self.apptentiveID = tmpID;
	}
}

- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if (self.clientCreationTime != nil) {
		result[@"client_created_at"] = [ATRecord serverFormatForTimeInterval:(NSTimeInterval)[self.clientCreationTime doubleValue]];
	}
	if (self.clientCreationTimezone != nil) {
		result[@"client_created_at_timezone"] = self.clientCreationTimezone;
	}
	if (self.clientCreationUTCOffset != nil) {
		result[@"client_created_at_utc_offset"] = self.clientCreationUTCOffset;
	}
	return result;
}

- (void)setup {
	if ([self isClientCreationTimeEmpty]) {
		[self updateClientCreationTime];
	}
}

- (void)updateClientCreationTime {
	self.clientCreationTime = [NSNumber numberWithDouble:(double)[[NSDate date] timeIntervalSince1970]];
}

- (BOOL)isClientCreationTimeEmpty {
	if (self.clientCreationTime == nil || [self.clientCreationTime doubleValue] == 0) {
		return YES;
	}
	return NO;
}
@end
