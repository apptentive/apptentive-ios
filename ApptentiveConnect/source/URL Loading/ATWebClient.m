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
#import "ATFeedback.h"
#import "ATURLConnection.h"
#import "ATUtilities.h"
#import "ATWebClient_Private.h"

#import "PJSONKit.h"

#import "NSData+ATBase64.h"

#define kCommonChannelName (@"ATWebClient")
#define kUserAgentFormat (@"ApptentiveConnect/%@ (%@)")

#if USE_STAGING
#define kApptentiveBaseURL (@"http://api.apptentive-beta.com")
#else
#define kApptentiveBaseURL (@"https://api.apptentive.com")
#endif

static ATWebClient *sharedSingleton = nil;

@implementation ATWebClient
+ (ATWebClient *)sharedClient {
	@synchronized(self) {
		if (sharedSingleton == nil) {
			sharedSingleton = [[ATWebClient alloc] init];
		}
	}
	return sharedSingleton;
}

- (NSString *)baseURLString {
	return kApptentiveBaseURL;
}

- (NSString *)commonChannelName {
	return kCommonChannelName;
}

- (ATAPIRequest *)requestForPostingFeedback:(ATFeedback *)feedback {
	NSDictionary *postData = [feedback apiDictionary];
	NSString *url = [self apiURLStringWithPath:@"records"];
	ATURLConnection *conn = nil;
	
	if (feedback.screenshot) {
#if TARGET_OS_IPHONE
		NSData *fileData = UIImagePNGRepresentation(feedback.screenshot);
#elif TARGET_OS_MAC
		NSData *fileData = [ATUtilities pngRepresentationOfImage:feedback.screenshot];
#endif
		conn = [self connectionToPost:[NSURL URLWithString:url] withFileData:fileData ofMimeType:@"image/png" fileDataKey:@"record[file][screenshot]" parameters:postData];
	} else {
		conn = [self connectionToPost:[NSURL URLWithString:url] parameters:postData];
	}
	conn.timeoutInterval = 240.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeData;
	return [request autorelease];
}

- (ATAPIRequest *)requestForGettingAppConfiguration {
	NSString *uuid = [[ATBackend sharedBackend] deviceUUID];
	NSString *urlString = [self apiURLStringWithPath:[NSString stringWithFormat:@"devices/%@/configuration", uuid]];
	ATURLConnection *conn = [self connectionToGet:[NSURL URLWithString:urlString]];
	conn.timeoutInterval = 20.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:[self commonChannelName]];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
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
	return [result autorelease];
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
	return [conn autorelease];
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	return [conn autorelease];
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	[conn setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	int length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return [conn autorelease];
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
	int length = [body lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	[conn setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];
	[conn setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
	return [conn autorelease];
}

- (ATURLConnection *)connectionToPost:(NSURL *)theURL withFileData:(NSData *)data ofMimeType:(NSString *)mimeType fileDataKey:(NSString *)fileDataKey parameters:(NSDictionary *)parameters {
	ATURLConnection *conn = [[ATURLConnection alloc] initWithURL:theURL];
	[self addAPIHeaders:conn];
	[conn setHTTPMethod:@"POST"];
	
	NSDictionary *postParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
	
	// Figure out boundary string.
	NSString *boundary = nil;
	while (YES) {
		boundary = [ATUtilities randomStringOfLength:20];
		NSData *boundaryData = [boundary dataUsingEncoding:NSUTF8StringEncoding];
		BOOL found = NO;
		for (NSString *key in [postParameters allKeys]) {
			id value = [postParameters objectForKey:key];
			if ([value isKindOfClass:[NSString class]]) {
				NSRange range = [(NSString *)value rangeOfString:boundary];
				if (range.location != NSNotFound) {
					found = YES;
					break;
				}
			} else if ([value isKindOfClass:[NSData class]]) {
				NSRange range = [(NSData *)value rangeOfData:boundaryData options:0 range:NSMakeRange(0, [(NSData *)value length])];
				if (range.location != NSNotFound) {
					found = YES;
					break;
				}
			} else {
				NSString *className = @"id";
				if ([value isKindOfClass:[NSObject class]]) {
					className = [NSString stringWithCString:object_getClassName((NSObject *)value) encoding:NSUTF8StringEncoding];
				}
				[conn release], conn = nil;
				@throw [NSException exceptionWithName:@"ATWebClientException" reason:[NSString stringWithFormat:@"Can't encode form data of class: %@", className] userInfo:nil];
			}
		}
		if (!found) {
			break;
		}
	}
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; charset=utf-8; boundary=%@", boundary];
	[conn setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	
	NSMutableData *multipartEncodedData = [NSMutableData data];
	if (data) {
		[postParameters setValue:data forKey:fileDataKey];
	}
	
	[multipartEncodedData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	for (NSString *key in [postParameters allKeys]) {
		id value = [postParameters objectForKey:key];
		[multipartEncodedData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		if ([value isKindOfClass:[NSString class]]) {
			[multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			[multipartEncodedData appendData:[(NSString *)value dataUsingEncoding:NSUTF8StringEncoding]];
		} else if ([value isKindOfClass:[NSData class]]) {
			[multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, [ATUtilities randomStringOfLength:10]] dataUsingEncoding:NSUTF8StringEncoding]];
			[multipartEncodedData appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
			[multipartEncodedData appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
			[multipartEncodedData appendData:(NSData *)value];
		} // else Should be handled above.
	}
	[multipartEncodedData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[conn setHTTPBody:multipartEncodedData];
	
	// Debugging helpers:
	/*
	 NSLog(@"wtf parameters: %@", parameters);
	 NSLog(@"-length: %d", [multipartEncodedData length]);
	 NSLog(@"-data: %@", [NSString stringWithUTF8String:[multipartEncodedData bytes]]);
	 */
	return [conn autorelease];
}

- (void)addAPIHeaders:(ATURLConnection *)conn {
	[conn setValue:[self userAgentString] forHTTPHeaderField:@"User-Agent"];
	[conn setValue: @"gzip" forHTTPHeaderField: @"Accept-Encoding"];
	[conn setValue: @"text/xml" forHTTPHeaderField: @"Accept"];
	[conn setValue: @"utf-8" forHTTPHeaderField: @"Accept-Charset"];
	NSString *apiKey = [[ATBackend sharedBackend] apiKey];
	if (apiKey) {
		NSString *value = [NSString stringWithFormat:@"OAuth %@", apiKey];
		[conn setValue:value forHTTPHeaderField:@"Authorization"];
	}
}
@end
