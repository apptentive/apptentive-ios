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
#import "ATMessage.h"
#import "ATFileAttachment.h"
#import "ATJSONSerialization.h"
#import "ATURLConnection.h"
#import "ATWebClient_Private.h"

#define kMessageCenterChannelName (@"Message Center")

@implementation ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingConversation:(ATConversation *)conversation {
	NSError *error = nil;
	NSDictionary *postJSON = nil;
	if (conversation == nil) {
		postJSON = [NSDictionary dictionary];
	} else {
		postJSON = [conversation apiJSON];
	}
	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"conversation"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	
	conn.timeoutInterval = 60.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForUpdatingConversation:(ATConversation *)conversation {
	NSError *error = nil;
	NSDictionary *putJSON = nil;
	if (conversation == nil) {
		return nil;
	}
	putJSON = [conversation apiUpdateJSON];
	NSString *putString = [ATJSONSerialization stringWithJSONObject:putJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!putString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"conversation"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPut:[NSURL URLWithString:url] JSON:putString];
	
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForUpdatingDevice:(ATDeviceInfo *)deviceInfo {
	NSError *error = nil;
	NSDictionary *postJSON = [deviceInfo apiJSON];
	
	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}
	
	NSString *url = [self apiURLStringWithPath:@"devices"];
	
	ATURLConnection *conn = [self connectionToPut:[NSURL URLWithString:url] JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForUpdatingPerson:(ATPersonInfo *)personInfo {
	NSError *error = nil;
	NSDictionary *postJSON = [personInfo apiJSON];
	
	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}
	
	NSString *url = [self apiURLStringWithPath:@"people"];
	
	ATURLConnection *conn = [self connectionToPut:[NSURL URLWithString:url] JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForPostingMessage:(ATMessage *)message {
	NSError *error = nil;
	NSDictionary *postJSON = [message apiJSON];

	NSString *postString = [ATJSONSerialization stringWithJSONObject:postJSON options:ATJSONWritingPrettyPrinted error:&error];
	if (!postString && error != nil) {
		ATLogError(@"Error while encoding JSON: %@", error);
		return nil;
	}
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation");
		return nil;
	}
	NSString *path = @"messages";
	NSString *urlString = [self apiURLStringWithPath:path];
	NSURL *url = [NSURL URLWithString:urlString];

	ATURLConnection *conn = [self connectionToPost:url JSON:postString withAttachments:message.attachments.array];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATMessage *)message {
	NSDictionary *parameters = nil;
	if (message && message.apptentiveID) {
		parameters = @{@"after_id":message.apptentiveID};
	}
	
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}
	
	NSString *path = @"conversation";
	if (parameters) {
		NSString *paramString = [self stringForParameters:parameters];
		path = [NSString stringWithFormat:@"%@?%@", path, paramString];
	}
	NSString *url = [self apiURLStringWithPath:path];
	
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:url]];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}
@end
