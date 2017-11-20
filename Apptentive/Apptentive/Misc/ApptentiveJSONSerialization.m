//
//  ApptentiveJSONSerialization.m
//  Apptentive
//
//  Created by Andrew Wooster on 6/22/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveJSONSerialization.h"

NS_ASSUME_NONNULL_BEGIN

NSInteger ApptentiveJSONDeserializationErrorCode = -567;
NSInteger ApptentiveJSONSerializationErrorCode = -568;


@implementation ApptentiveJSONSerialization

+ (NSData *)dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
	if ([NSJSONSerialization isValidJSONObject:obj]) {
		NSData *jsonData = nil;
		@try {
			jsonData = [NSJSONSerialization dataWithJSONObject:obj options:opt error:error];
		} @catch (NSException *exception) {
			if (error != NULL) {
				*error = [NSError errorWithDomain:ApptentiveErrorDomain code:ApptentiveJSONSerializationErrorCode userInfo:@{ NSLocalizedFailureReasonErrorKey: @"JSON object is malformed." }];
			}

			ApptentiveLogError(@"Exception when encoding JSON: %@.", exception.reason);
			ApptentiveLogError(@"Attempted to encode %@.", obj);
		}

		return jsonData;
	} else {
		if (error != NULL) {
			*error = [NSError errorWithDomain:ApptentiveErrorDomain code:ApptentiveJSONDeserializationErrorCode userInfo:@{ NSLocalizedFailureReasonErrorKey: @"Object is not valid JSON object." }];
		}

		ApptentiveLogError(@"Attempting to create JSON data from an invalid JSON object (%@).", obj);

		return nil;
	}
}

+ (id)JSONObjectWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
	id JSONObject = nil;

	if (data == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:ApptentiveErrorDomain code:ApptentiveJSONDeserializationErrorCode userInfo:@{ NSLocalizedFailureReasonErrorKey: @"JSON data is nil." }];
		}

		ApptentiveLogError(@"Attempting to decode nil JSON data.");

		return nil;
	}

	@try {
		JSONObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:error];

		return JSONObject;
	} @catch (NSException *exception) {
		if (error != NULL) {
			*error = [NSError errorWithDomain:ApptentiveErrorDomain code:ApptentiveJSONSerializationErrorCode userInfo:@{ NSLocalizedFailureReasonErrorKey: @"JSON data is malformed." }];
		}

		ApptentiveLogError(@"Exception when decoding JSON: %@", exception.reason);
		ApptentiveLogError(@"Attempted to decode “%@”", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);

		return nil;
	}
}

+ (id)JSONObjectWithString:(NSString *)string error:(NSError **)error {
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [self JSONObjectWithData:data error:error];
}

@end

NS_ASSUME_NONNULL_END
