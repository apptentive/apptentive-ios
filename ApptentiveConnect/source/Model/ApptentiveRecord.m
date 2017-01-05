//
//  ApptentiveRecord.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/3/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

@implementation ApptentiveRecord

- (instancetype)initWithNoncePrefix:(NSString *)noncePrefix payload:(NSDictionary *)payload {
	self = [super init];

	if (self) {
		_nonce = [NSString stringWithFormat:@"%@:%@", noncePrefix, [NSUUID UUID].UUIDString];
		_clientCreatedAt = [NSDate date];
		_clientCreatedAtUTCOffset = [[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]];
	}

	return self;
}

- (NSDictionary *)JSONDictionary {
	return @{
		@"client_created_at": @(self.clientCreatedAt.timeIntervalSince1970),
		@"client_created_at_utc_offset": @(self.clientCreatedAtUTCOffset),
		@"nonce": self.nonce
	};
}

/* 
 survey[@"client_created_at"] = @([NSDate distantFuture].timeIntervalSince1970);
	survey[@"client_created_at_utc_offset"] = @([[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]]);

	survey[@"id"] = self.interaction.identifier;
	survey[@"nonce"] = [NSString stringWithFormat:@"pending-survey-response:%@", [NSUUID UUID].UUIDString];
	survey[@"answers"] = self.answers;

	NSString *path = [NSString stringWithFormat:@"/surveys/%@/respond", self.interaction.identifier];

	[ApptentiveSerialRequest enqueueRequestWithPath:path method:@"POST" payload:@{ @"survey": survey } attachments:nil identifier:nil inContext:Apptentive.shared.backend.managedObjectContext];
*/


@end
