//
//  ApptentiveRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "Apptentive.h"
#import "ApptentiveDefines.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveRequest.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveRequest

- (NSString *)apiVersion {
	return kApptentiveAPIVersionString;
}

- (NSString *)path {
	APPTENTIVE_ABSTRACT_METHOD_CALLED

	return @"";
}

- (NSString *)method {
	return @"GET";
}

- (NSString *)contentType {
	return @"application/json";
}

- (nullable NSDictionary *)JSONDictionary {
	return nil;
}

- (nullable NSData *)payload {
	if (self.JSONDictionary == nil) {
		return nil;
	}

	NSError *error;
	NSData *payloadData = [ApptentiveJSONSerialization dataWithJSONObject:self.JSONDictionary options:0 error:&error];

	ApptentiveAssertNotNil(payloadData, @"JSONDictionary was not serializable into JSON data (%@)", error);

	return payloadData;
}

- (BOOL)encrypted {
	return NO;
}

- (NSString *)conversationIdentifier {
	APPTENTIVE_ABSTRACT_METHOD_CALLED
	return @"INVALID";
}

@end

NS_ASSUME_NONNULL_END
