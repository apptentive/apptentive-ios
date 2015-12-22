//
//  ATWebClient_Private.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATURLConnection;
@class ATWebClient;


@interface ATWebClient ()
- (NSString *)userAgentString;

#pragma mark API URL String
- (NSURL *)APIURLWithPath:(NSString *)path;

#pragma mark Query Parameter Encoding
- (NSString *)stringForParameters:(NSDictionary *)parameters;
- (NSString *)stringForParameter:(id)value;

#pragma mark Internal Methods
- (ATURLConnection *)connectionToGet:(NSString *)path;
- (ATURLConnection *)connectionToPost:(NSString *)path;
- (ATURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSString *)path parameters:(NSDictionary *)parameters;
- (ATURLConnection *)connectionToPost:(NSString *)path body:(NSString *)body;
- (ATURLConnection *)connectionToPost:(NSString *)path JSON:(NSString *)body withAttachments:(NSArray *)attachments;
- (ATURLConnection *)connectionToPut:(NSString *)path JSON:(NSString *)body;
- (void)addAPIHeaders:(ATURLConnection *)conn;
- (void)updateConnection:(ATURLConnection *)conn withOAuthToken:(NSString *)token;
@end
