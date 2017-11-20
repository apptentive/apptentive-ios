//
//  ApptentiveConversationRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationRequest.h"
#import "ApptentiveAppInstall.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveDefines.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveConversationRequest

- (nullable instancetype)initWithAppInstall:(id<ApptentiveAppInstall>)appInstall {
	self = [super init];

	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(appInstall.appRelease.JSONDictionary);
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(appInstall.person.JSONDictionary);
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(appInstall.device.JSONDictionary);

	if (self) {
		_appInstall = appInstall;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	return @"conversations";
}

- (NSString *)conversationIdentifier {
	return self.appInstall.identifier;
}

- (NSDictionary *)JSONDictionary {
	// Combine app release and SDK JSON payloads
	NSMutableDictionary *appReleaseJSON = [self.appInstall.appRelease.JSONDictionary mutableCopy];
	[appReleaseJSON addEntriesFromDictionary:self.appInstall.SDK.JSONDictionary];

	return @{
		@"app_release": appReleaseJSON,
		@"person": self.appInstall.person.JSONDictionary,
		@"device": self.appInstall.device.JSONDictionary
	};
}

@end

NS_ASSUME_NONNULL_END
