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
#import "ATCompoundMessage.h"
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

	ATURLConnection *conn = [self connectionToPost:@"/conversation" JSON:postString];
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

	ATURLConnection *conn = [self connectionToPut:@"/conversation" JSON:putString];
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

	ATURLConnection *conn = [self connectionToPut:@"/devices" JSON:postString];
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

	ATURLConnection *conn = [self connectionToPut:@"/people" JSON:postString];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForPostingMessage:(ATCompoundMessage *)message {
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

	ATURLConnection *conn = [self connectionToPost:@"/messages" JSON:postString withAttachments:message.attachments.array];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}

- (ATAPIRequest *)requestForRetrievingMessagesSinceMessage:(ATCompoundMessage *)message {
	NSDictionary *parameters = nil;
	if (message && message.apptentiveID) {
		parameters = @{ @"after_id": message.apptentiveID };
	}

	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		ATLogError(@"No current conversation.");
		return nil;
	}

	NSString *path = @"/conversation";
	if (parameters) {
		NSString *paramString = [self stringForParameters:parameters];
		path = [NSString stringWithFormat:@"%@?%@", path, paramString];
	}

	ATURLConnection *conn = [self connectionToGet:path];
	conn.timeoutInterval = 60.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}
@end
