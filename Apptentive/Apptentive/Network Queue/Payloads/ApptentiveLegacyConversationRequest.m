//
//  ApptentiveLegacyConversationRequest.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/15/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyConversationRequest.h"


@implementation ApptentiveLegacyConversationRequest

- (instancetype)initWithConversation:(ApptentiveConversation *)conversation {
	self = [super init];

	if (self) {
		if (conversation == nil) {
			ApptentiveLogError(@"Can't init %@: conversation is nil");
			return nil;
		}
		_conversation = conversation;
	}

	return self;
}

- (NSString *)method {
	return @"POST";
}

- (NSString *)path {
	return @"conversation/login";
}

- (NSDictionary *)JSONDictionary {
	return @{}; // TODO: pass params?
}


@end
