//
//  ApptentiveConversation.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 2/4/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"

#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveUtilities.h"
#import "NSDictionary+Apptentive.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveConsumerData.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"

#define kATConversationCodingVersion 1


@implementation ApptentiveConversation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATConversation"];
}

- (instancetype)init
{
	self = [super init];

	if (self) {
		_deviceID = Apptentive.shared.backend.deviceUUID;
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
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

+ (instancetype)newInstanceWithJSON:(NSDictionary *)json inContext:(NSManagedObjectContext *)context {
	ApptentiveConversation *result = nil;

	if (json != nil) {
		result = [[ApptentiveConversation alloc] init];
		[result updateWithJSON:json];
	} else {
		ApptentiveLogError(@"Conversation JSON was nil");
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

//TODO: Add support for sending person.
- (NSDictionary *)apiJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	result[@"person"] = Apptentive.shared.backend.session.person.JSONDictionary;
	result[@"device"] = Apptentive.shared.backend.session.device.JSONDictionary;
	result[@"app_release"] = Apptentive.shared.backend.session.appRelease.JSONDictionary;
	result[@"sdk"] = Apptentive.shared.backend.session.SDK.JSONDictionary;

	return result;
}

- (NSDictionary *)apiUpdateJSON {
	NSMutableDictionary *result = [NSMutableDictionary dictionary];

	result[@"app_release"] = Apptentive.shared.backend.session.appRelease.JSONDictionary;
	result[@"sdk"] = Apptentive.shared.backend.session.SDK.JSONDictionary;

	return result;
}
@end
