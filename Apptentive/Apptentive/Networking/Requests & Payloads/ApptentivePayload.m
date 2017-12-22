//
//  ApptentivePayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/19/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayload.h"
#import "ApptentiveDefines.h"
#import "ApptentiveJSONSerialization.h"
#import "ApptentiveUtilities.h"
#import "NSData+Encryption.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentivePayload

- (instancetype)init {
	return [self initWithCreationDate:[NSDate date]];
}

- (instancetype)initWithCreationDate:(NSDate *)creationDate {
	self = [super init];
	if (self) {
		_contents = @{
			@"nonce": [NSUUID UUID].UUIDString,
			@"client_created_at": @(creationDate.timeIntervalSince1970),
			@"client_created_at_utc_offset": @([[NSTimeZone systemTimeZone] secondsFromGMTForDate:creationDate])
		};
	}
	return self;
}

- (NSString *)type {
	APPTENTIVE_ABSTRACT_METHOD_CALLED

	return @"";
}

- (NSString *)containerName {
	APPTENTIVE_ABSTRACT_METHOD_CALLED

	return @"";
}

- (NSString *)apiVersion {
	return kApptentiveAPIVersionString;
}

- (NSString *)path {
	APPTENTIVE_ABSTRACT_METHOD_CALLED

	return @"";
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)contentType {
	if (self.encryptionKey != nil) {
		return @"application/octet-stream";
	} else {
		return @"application/json";
	}
}

- (NSDictionary *)JSONDictionary {
	NSMutableDictionary *dictionary = [NSMutableDictionary new];
	ApptentiveDictionarySetKeyValue(dictionary, self.containerName, self.contents);
	return dictionary;
}

- (nullable NSData *)payload {
	NSData *payloadData = [self marshalForSending];
	if (self.encryptionKey != nil) {
		return [payloadData apptentive_dataEncryptedWithKey:self.encryptionKey];
	}
	return payloadData;
}

- (NSData *)marshalForSending {
	NSDictionary *payloadJson = self.JSONDictionary;
	ApptentiveAssertNotNil(payloadJson, @"JSONDictionary is nil");

	// for each encrypted payload we should include token into JSON-body
	if (self.encryptionKey != nil) {
		ApptentiveAssertNotNil(self.token, @"Token is nil");
		NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithDictionary:payloadJson];
		ApptentiveDictionarySetKeyValue(temp, @"token", self.token);
		payloadJson = temp;
	}

	NSError *error;
	NSData *payloadData = [ApptentiveJSONSerialization dataWithJSONObject:payloadJson options:0 error:&error];

	ApptentiveAssertNotNil(payloadData, @"JSONDictionary was not serializable into JSON data: %@", error);
	return payloadData;
}

- (nullable NSArray *)attachments {
	return nil;
}

- (nullable NSString *)localIdentifier {
	return nil;
}

- (BOOL)encrypted {
	return self.encryptionKey != nil;
}

@end

NS_ASSUME_NONNULL_END
