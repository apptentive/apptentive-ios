//
//  ATWebClient+Metrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive. All rights reserved.
//

#import "ATWebClient+Metrics.h"
#import "ATWebClient_Private.h"
#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATEvent.h"
#import "ATMetric.h"
#import "ATJSONSerialization.h"
#import "ATURLConnection.h"
#import "ATConversation.h"


@implementation ATWebClient (Metrics)
- (ATAPIRequest *)requestForSendingMetric:(ATMetric *)metric {
	NSDictionary *postData = [metric apiDictionary];

	ATURLConnection *conn = [self connectionToPost:@"/records" parameters:postData];
	conn.timeoutInterval = 240.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForSendingEvent:(ATEvent *)event {
	NSDictionary *postJSON = [event apiJSON];
	if (postJSON == nil) {
		return nil;
	}

	NSError *error = nil;
	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	ATConversation *conversation = [ATConnect sharedConnection].backend.currentConversation;
	if (!conversation.token) {
		ATLogError(@"No current conversation.");
		return nil;
	}

	ATURLConnection *conn = [self connectionToPost:@"/events" JSON:postString];
	conn.timeoutInterval = 240.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:ATWebClientDefaultChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}
@end
