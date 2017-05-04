//
//  ApptentiveRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRequest.h"


@implementation ApptentiveRequest

- (NSString *)apiVersion {
	return @"8";
}

- (NSString *)path {
	ApptentiveAssertTrue(NO, @"Abstract method called");

	return @"";
}

- (NSString *)method {
	return @"GET";
}

- (NSString *)contentType {
	return @"application/json";
}

- (NSDictionary *)JSONDictionary {
	return nil;
}

- (NSData *)payload {
	if (self.JSONDictionary == nil) {
		return nil;
	}

	NSError *error;
	NSData *payloadData = [NSJSONSerialization dataWithJSONObject:self.JSONDictionary options:0 error:&error];

	ApptentiveAssertNotNil(payloadData, @"JSONDictionary was not serializable into JSON data (%@)", error);

	return payloadData;
}

- (BOOL)encrypted {
	return NO;
}

@end
