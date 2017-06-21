//
//  ApptentiveConversationPayload.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSDKAppReleasePayload.h"
#import "ApptentiveConversation.h"


@implementation ApptentiveSDKAppReleasePayload

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation {
	self = [super init];

	if (self) {
		_conversation = conversation;
	}

	return self;
}

- (NSString *)type {
	return @"sdk_app_release";
}

- (NSString *)path {
	return @"conversations/<cid>/app_release";
}

- (NSString *)method {
	return @"PUT";
}

- (NSDictionary *)JSONDictionary {
	return @{
		@"app_release": self.conversation.appReleaseSDKJSON,
	};
}

@end
