//
//  ApptentivePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"


@implementation ApptentivePayload

- (instancetype)init {
	self = [super init];
	if (self) {
		_contents = @{
			@"nonce": [NSUUID UUID].UUIDString,
			@"client_created_at": @([NSDate date].timeIntervalSince1970),
			@"client_created_at_utc_offset": @([[NSTimeZone systemTimeZone] secondsFromGMTForDate:[NSDate date]])
		};
	}
	return self;
}

- (NSString *)containerName {
	ApptentiveAssertTrue(NO, @"Abstract method called");

	return @"";
}

- (NSString *)apiVersion {
	return @"8";
}

- (NSString *)path {
	ApptentiveAssertTrue(NO, @"Abstract method called");

	return @"";
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)contentType {
	return @"application/json";
}

- (NSDictionary *)JSONDictionary {
	return @{self.containerName: self.contents};
}

- (NSData *)payload {
	NSError *error;
	NSData *payloadData = [NSJSONSerialization dataWithJSONObject:self.JSONDictionary options:0 error:&error];

	ApptentiveAssertNotNil(payloadData, @"JSONDictionary was not serializable into JSON data (%@)", error);

	return payloadData;
}

- (NSArray *)attachments {
	return nil;
}

- (NSString *)localIdentifier {
	return nil;
}

@end
