//
//  ATWebClient+MessageCenter.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient+MessageCenter.h"

#import "ATAPIRequest.h"
#import "ATBackend.h"
#import "ATURLConnection.h"
#import "ATWebClient_Private.h"

#import "PJSONKit.h"

#define kMessageCenterChannelName (@"Message Center")

@implementation ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingActivityFeed:(ATActivityFeed *)activityFeed {
	NSError *error = nil;
	NSDictionary *postJSON = nil;
	if (activityFeed == nil) {
		postJSON = [NSDictionary dictionary];
	} else {
		postJSON = [activityFeed apiJSON];
	}
	NSString *postString = [postJSON ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		NSLog(@"ATWebClient+MessageCenter: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"activity_feed"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	
	conn.timeoutInterval = 60.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}

- (ATAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo {
	NSError *error = nil;
	NSDictionary *postJSON = [deviceInfo apiJSON];
	
	NSString *postString = [postJSON ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		NSLog(@"ATWebClient+MessageCenter: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *path = [NSString stringWithFormat:@"devices/%@", [[ATBackend sharedBackend] deviceUUID]];
	NSString *url = [self apiURLStringWithPath:path];
	
	ATURLConnection *conn = [self connectionToPut:[NSURL URLWithString:url] JSON:postString];
	conn.timeoutInterval = 60.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}

- (ATAPIRequest *)requestForPostingMessage:(ATMessage *)message {
	NSError *error = nil;
	NSDictionary *messageJSON = [message apiJSON];
	NSDictionary *postJSON = @{@"message":messageJSON};
	
	NSString *postString = [postJSON ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		NSLog(@"ATWebClient+MessageCenter: Error while encoding JSON: %@", error);
		return nil;
	}
	
	ATActivityFeed *feed = [ATActivityFeedUpdater currentActivityFeed];
	if (!feed) {
		NSLog(@"No current activity feed.");
		return nil;
	}
	NSString *path = @"messages";
	NSString *url = [self apiURLStringWithPath:path];
	
	ATURLConnection *conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:feed.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}

- (ATAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATMessage *)message {
	NSDictionary *parameters = nil;
	if (message && message.apptentiveID) {
		parameters = @{@"after_id":message.apptentiveID};
	}
	
	ATActivityFeed *feed = [ATActivityFeedUpdater currentActivityFeed];
	if (!feed) {
		NSLog(@"No current activity feed.");
		return nil;
	}
	
	NSString *path = @"activity_feed";
	if (parameters) {
		NSString *paramString = [self stringForParameters:parameters];
		path = [NSString stringWithFormat:@"%@?%@", path, paramString];
	}
	NSString *url = [self apiURLStringWithPath:path];
	
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:url]];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:feed.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}
@end
