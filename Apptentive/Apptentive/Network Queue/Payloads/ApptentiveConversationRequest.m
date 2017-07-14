//
//  ApptentiveConversationRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationRequest.h"
#import "ApptentiveAppInstall.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveSDK.h"
#import "ApptentiveAppRelease.h"


@implementation ApptentiveConversationRequest

- (instancetype)initWithAppInstall:(id<ApptentiveAppInstall>)appInstall {
	self = [super init];

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
