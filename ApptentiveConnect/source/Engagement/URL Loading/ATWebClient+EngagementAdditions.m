//
//  ATWebClient+EngagementAdditions.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 8/19/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient+EngagementAdditions.h"
#import "ATWebClient_Private.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"
#import "ATURLConnection.h"
#import "ATAPIRequest.h"
#import "ATConversationUpdater.h"
#import "ATConversation.h"


@implementation ATWebClient (EngagementAdditions)

- (ATAPIRequest *)requestForGettingEngagementManifest {
	ATURLConnection *conn = [self connectionToGet:@"/interactions"];
	conn.timeoutInterval = 20.0;

	ATConversation *conversation = [ATConnect sharedConnection].backend.currentConversation;
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
