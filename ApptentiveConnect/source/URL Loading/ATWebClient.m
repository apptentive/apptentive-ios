//
//  ATWebClient.m
//  apptentive-ios
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Apptentive, Inc.. All rights reserved.
//

#import "ATWebClient.h"
#import "ATWebClient_Private.h"
#import "ATAPIRequest.h"
#import "ATURLConnection.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConversationUpdater.h"
#import "ATURLConnection.h"
#import "ATUtilities.h"
#import "ATWebClient_Private.h"

NSString *const ATWebClientDefaultChannelName = @"ATWebClient";

#define kUserAgentFormat (@"ApptentiveConnect/%@ (%@)")

#if USE_STAGING
#define kApptentiveBaseURL (@"https://api.apptentive-beta.com")
#else
#define kApptentiveBaseURL (@"https://api.apptentive.com")
#endif

@implementation ATWebClient
+ (ATWebClient *)sharedClient {
	static ATWebClient *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ATWebClient alloc] init];
	});
	return sharedSingleton;
}

- (NSString *)baseURLString {
	return kApptentiveBaseURL;
}

- (NSString *)commonChannelName {
	return ATWebClientDefaultChannelName;
}

- (ATAPIRequest *)requestForGettingAppConfiguration {
	ATConversation *conversation = [ATConversationUpdater currentConversation];
	if (!conversation) {
		return nil;
	}
	NSString *urlString = [self apiURLStringWithPath:@"conversation/configuration"];
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:urlString]];
	conn.timeoutInterval = 20.0;
	[self updateConnection:conn withOAuthToken:conversation.token];
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return request;
}
@end


@implementation ATWebClient (Private)

- (NSString *)stringForParameters:(NSDictionary *)parameters {
	NSMutableString *result = [[NSMutableString alloc] init];
	do { // once
		if (!parameters || [parameters count] == 0) {
			[result appendString:@""];
			break;
		}
		
		BOOL appendAmpersand = NO;
		for (NSString *key in [parameters keyEnumerator]) {
			NSString *val = [self stringForParameter:[parameters objectForKey:key]];
			if (!val) continue;
			
			if (appendAmpersand) {
				[result appendString:@"&"];
			}
			[result appendString:[ATUtilities stringByEscapingForURLArguments:key]];
			[result appendString:@"="];
			[result appendString:[ATUtilities stringByEscapingForURLArguments:val]];
			appendAmpersand = YES;
		}
	} while (NO);
	return result;
}

- (NSString *)stringForParameter:(id)value {
	NSString *result = nil;
	if ([value isKindOfClass:[NSString class]]) {
		result = (NSString *)value;
	} else if ([value isKindOfClass:[NSNumber class]]) {
		result = [(NSNumber *)value stringValue];
	}
	return result;
}


- (NSString *)apiBaseURLString {
	return kApptentiveBaseURL;
}

- (NSString *)apiURLStringWithPath:(NSString *)path {
	return [NSString stringWithFormat:@"%@/%@", kApptentiveBaseURL, path];
}

- (NSString *)userAgentString {
	return [NSString stringWithFormat:kUserAgentFormat, kATConnectVersionString, kATConnectPlatformString];
}

- (ATURLConnection *)connectionToGet:(NSURL *)theURL {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	return conn;
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	return conn;
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	NSUInteger length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%lu", (unsigned long)length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return conn;
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL parameters:(NSDictionary *)parameters {
	NSDictionary *postParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	NSString *bodyString = [self stringForParameters:postParameters];
	return [self connectionToPost:theURL body:bodyString];
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL body:(NSString *)body {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	NSUInteger length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%lu", (unsigned long)length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return conn;
}

- (ATURLConnection *)connectionToPut:(NSURL *)theURL JSON:(NSString *)body {
	ATURLConnection *conn = [self connectionToPost:theURL JSON:body];
	[conn setHTTPMethod:@"PUT"];
	return conn;
}

- (void)addAPIHeaders:(ATURLConnection *)conn {
	[conn setValue:[self userAgentString] forHTTPHeaderField:@"User-Agent"];
	[conn setValue: @"gzip" forHTTPHeaderField: @"Accept-Encoding"];
//!!	[conn setValue: @"text/xml" forHTTPHeaderField: @"Accept"];
	[conn setValue: @"utf-8" forHTTPHeaderField: @"Accept-Charset"];

	// Apptentive API Version
    [conn setValue:@"4" forHTTPHeaderField:@"X-API-Version"];

	NSString *apiKey = [[ATBackend sharedBackend] apiKey];
	if (apiKey) {
		[self updateConnection:conn withOAuthToken:apiKey];
	}
}

- (void)updateConnection:(ATURLConnection *)conn withOAuthToken:(NSString *)token {
	if (token) {
		NSString *value = [NSString stringWithFormat:@"OAuth %@", token];
		[conn setValue:value forHTTPHeaderField:@"Authorization"];
	} else {
		[conn removeHTTPHeaderField:@"Authorization"];
	}
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body withAttachments:(NSArray *)attachments {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	NSString *boundary = [ATUtilities randomStringOfLength:20];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[conn setValue:contentType forHTTPHeaderField:@"Content-Type"];

	NSMutableData *multipartEncodedData = [NSMutableData data];
	//[multipartEncodedData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	NSMutableString *debugString = [NSMutableString string];

	for (NSString *key in [conn headers]) {
		[debugString appendFormat:@"%@: %@\n", key, [[conn headers] objectForKey:key]];
	}
	[debugString appendString:@"\n"];

	if (body) {
		NSMutableString *bodyHeader = [NSMutableString string];
		[bodyHeader appendString:[NSString stringWithFormat:@"--%@\r\n", boundary]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", @"text/plain"]];
		[bodyHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", @"message"]];
		[debugString appendString:bodyHeader];

		[multipartEncodedData appendData:[bodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:[(NSString *)body dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:body];
	}

	for (ATFileAttachment *attachment in attachments) {
		NSString *boundaryString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
		[multipartEncodedData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
		[debugString appendString:boundaryString];

		NSMutableString *multipartHeader = [NSMutableString string];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", @"file[]", attachment.name]];
		[multipartHeader appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n", attachment.mimeType]];
		[multipartHeader appendString:@"Content-Transfer-Encoding: binary\r\n\r\n"];
		[debugString appendString:multipartHeader];

		[multipartEncodedData appendData:[multipartHeader dataUsingEncoding:NSUTF8StringEncoding]];
		[multipartEncodedData appendData:attachment.fileData];
		[debugString appendFormat:@"<NSData of length: %lu>", (unsigned long)[attachment.fileData length]];
	}

	NSString *finalBoundary = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
	[multipartEncodedData appendData:[finalBoundary dataUsingEncoding:NSUTF8StringEncoding]];
	[debugString appendString:finalBoundary];

	//NSLog(@"\n%@", debugString);

	[conn setHTTPBody:multipartEncodedData];

	// Debugging helpers:
	/*
	 NSLog(@"wtf parameters: %@", parameters);
	 NSLog(@"-length: %d", [multipartEncodedData length]);
	 NSLog(@"-data: %@", [NSString stringWithUTF8String:[multipartEncodedData bytes]]);
	 */
	return conn;
}

@end
