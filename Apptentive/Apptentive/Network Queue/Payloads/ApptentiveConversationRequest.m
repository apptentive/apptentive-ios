//
//  ApptentiveConversationRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationRequest.h"
#import "ApptentiveConversation.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"


@implementation ApptentiveConversationRequest

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation {
	self = [super init];

	if (self) {
		_conversation = conversation;
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
	return @{
		@"app_release": self.conversation.appReleaseSDKJSON,
		@"person": self.conversation.person.JSONDictionary,
		@"device": self.conversation.device.JSONDictionary
	};
}

@end
