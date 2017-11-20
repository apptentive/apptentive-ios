//
//  ApptentiveMessageGetRequest.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageGetRequest.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveMessageGetRequest

- (NSString *)path {
	NSString *path = [NSString stringWithFormat:@"conversations/%@/messages", self.conversationIdentifier];

	// TODO: Move to separate query method
	if (self.lastMessageIdentifier != nil) {
		path = [path stringByAppendingFormat:@"?starts_after=%@", self.lastMessageIdentifier];
	}

	return path;
}

@end

NS_ASSUME_NONNULL_END
