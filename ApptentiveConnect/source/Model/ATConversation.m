//
//  ATConversation.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATConversation.h"

#import "ATConnect_Private.h"
#import "ATBackend.h"
#import "ATUtilities.h"
#import "NSDictionary+ATAdditions.h"

#define kATConversationCodingVersion 1


@implementation ATConversation

- (instancetype)init {
	self = [super init];
	if (self) {
		_deviceUUID = [ATUtilities currentDeviceID];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		_token = (NSString *)[coder decodeObjectForKey:@"token"];
		_personID = (NSString *)[coder decodeObjectForKey:@"personID"];
		_deviceID = (NSString *)[coder decodeObjectForKey:@"deviceID"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATConversationCodingVersion forKey:@"version"];

	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

+ (instancetype)newInstanceFromDictionary:(NSDictionary *)dictionary {
	ATConversation *result = nil;

	if (dictionary != nil) {
		result = [[ATConversation alloc] init];
		[result updateWithJSON:dictionary];
	} else {
		ATLogError(@"Conversation JSON was nil");
	}

	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tokenObject = [json at_safeObjectForKey:@"token"];
	if (tokenObject != nil) {
		_token = tokenObject;
	}
	NSString *deviceIDObject = [json at_safeObjectForKey:@"device_id"];
	if (deviceIDObject != nil) {
		_deviceID = deviceIDObject;
	}
	NSString *personIDObject = [json at_safeObjectForKey:@"person_id"];
	if (personIDObject != nil) {
		_personID = personIDObject;
	}
}

- (NSDictionary *)initialDictionaryRepresentation {
	NSMutableDictionary *result = [self.dictionaryRepresentation mutableCopy];

	if (self.deviceUUID) {
		result[@"device"] = @{ @"uuid":  self.deviceUUID.UUIDString };
	}

	return result;
}

- (NSDictionary *)appReleaseJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSString *appVersion = [ATUtilities appVersionString];
	if (appVersion) {
		result[@"version"] = appVersion;
	}

	NSString *buildNumber = [ATUtilities buildNumberString];
	if (buildNumber) {
		result[@"build_number"] = buildNumber;
	}

	NSString *appStoreReceiptFileName = [ATUtilities appStoreReceiptFileName];
	if (appStoreReceiptFileName) {
		NSDictionary *receiptInfo = @{ @"file_name": appStoreReceiptFileName,
			@"has_receipt": @([ATUtilities appStoreReceiptExists]),
		};

		result[@"app_store_receipt"] = receiptInfo;
	}

	return result;
}

- (NSDictionary *)sdkJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"version"] = kATConnectVersionString;
	result[@"programming_language"] = @"Objective-C";
	result[@"author_name"] = @"Apptentive, Inc.";
	result[@"platform"] = kATConnectPlatformString;
	NSString *distribution = [[ATConnect sharedConnection].backend distributionName];
	if (distribution) {
		result[@"distribution"] = distribution;
	}
	NSString *distributionVersion = [[ATConnect sharedConnection].backend distributionVersion];
	if (distributionVersion) {
		result[@"distribution_version"] = distributionVersion;
	}

	return result;
}

- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];
	return result;
}
@end
