//
//  ApptentiveLegacyConversationRequest.m
//  Apptentive
//
//  Created by Alex Lementuev on 5/15/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacyConversationRequest.h"
#import "ApptentiveConversation.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveLegacyConversationRequest

- (nullable instancetype)initWithConversation:(ApptentiveConversation *)conversation {
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
	return @"GET";
}

- (NSString *)path {
	return @"conversation/token";
}

- (NSDictionary *)JSONDictionary {
	return @{}; // TODO: pass params?
}

- (NSString *)conversationIdentifier {
	return @"#INVALID"; // FIXME: we need a not-nil value to keep logic consistent
}

@end

NS_ASSUME_NONNULL_END
