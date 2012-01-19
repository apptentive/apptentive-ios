//
//  ATWebClient_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATWebClient, ATURLConnection;

@interface ATWebClient (Private)
- (NSString *)userAgentString;

#pragma mark API URL String
- (NSString *)apiBaseURLString;
- (NSString *)apiURLStringWithPath:(NSString *)path;

#pragma mark Query Parameter Encoding
- (NSString *)stringForParameters:(NSDictionary *)parameters;
- (NSString *)stringForParameter:(id)value;

#pragma mark Internal Methods
- (ATURLConnection *)connectionToGet:(NSURL *)theURL;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL JSON:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL parameters:(NSDictionary *)parameters;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL body:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSURL *)theURL withFileData:(NSData *)data ofMimeType:(NSString *)mimeType fileDataKey:(NSString *)fileDataKey  parameters:(NSDictionary *)parameters;
- (void)addAPIHeaders:(ATURLConnection *)conn;
@end
