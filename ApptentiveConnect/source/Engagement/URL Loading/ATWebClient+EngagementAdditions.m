//
//  ATWebClient+EngagementAdditions.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient+EngagementAdditions.h"
#import "ATWebClient_Private.h"
#import "ATURLConnection.h"
#import "ATAPIRequest.h"
#import "ATConversationUpdater.h"


@implementation ATWebClient (EngagementAdditions)

- (ATAPIRequest *)requestForGettingEngagementManifest {
	ATURLConnection *conn = [self connectionToGet:[self APIURLWithPath:@"/interactions"]];
	conn.timeoutInterval = 20.0;

	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}
	[self updateConnection:conn withOAuthToken:conversation.token];

	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeData;
	return request;
}

@end
