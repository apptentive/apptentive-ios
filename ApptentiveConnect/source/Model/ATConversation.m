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

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		// Apptentive Conversation Token
		self.token = (NSString *)[coder decodeObjectForKey:@"token"];
		self.personID = (NSString *)[coder decodeObjectForKey:@"personID"];
		self.deviceID = (NSString *)[coder decodeObjectForKey:@"deviceID"];
	}
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATConversationCodingVersion forKey:@"version"];

	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json {
	ATConversation *result = nil;

	if (json != nil) {
		result = [[ATConversation alloc] init];
		[result updateWithJSON:json];
	} else {
		ATLogError(@"Conversation JSON was nil");
	}

	return result;
}

- (void)updateWithJSON:(NSDictionary *)json {
	NSString *tokenObject = [json at_safeObjectForKey:@"token"];
	if (tokenObject != nil) {
		self.token = tokenObject;
	}
	NSString *deviceIDObject = [json at_safeObjectForKey:@"device_id"];
	if (deviceIDObject != nil) {
		self.deviceID = deviceIDObject;
	}
	NSString *personIDObject = [json at_safeObjectForKey:@"person_id"];
	if (personIDObject != nil) {
		self.personID = personIDObject;
	}
}

//TODO: Add support for sending person.
- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	NSString *deviceUUID = [[ATConnect sharedConnection].backend deviceUUID];
	if (deviceUUID) {
		NSDictionary *deviceInfo = @{ @"uuid": deviceUUID };
		result[@"device"] = deviceInfo;
	}
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];

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

- (NSDictionary *)apiUpdateJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	result[@"app_release"] = [self appReleaseJSON];
	result[@"sdk"] = [self sdkJSON];
	return result;
}
@end
