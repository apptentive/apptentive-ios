//
//  PSWebClient.h
//  AmidstApp
//
//  Created by Andrew Wooster on 7/28/09.
//  Copyright 2009 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATURLConnection.h"

@class ATFeedback;

typedef enum {
	ATWebClientReturnTypeData,
	ATWebClientReturnTypeString
#ifdef SUPPORT_JSON
    ,
	ATWebClientReturnTypeJSON
#endif
} ATWebClientReturnType;

/*! A common base class for implementing clients of web services. */
@interface ATWebClient : NSObject <ATURLConnectionDelegate> {
	ATWebClientReturnType returnType;
	BOOL failed;
	BOOL cancelled;
	NSString *errorTitle;
	NSString *errorMessage;
	NSString *channelName;
	NSTimeInterval timeoutInterval;
	
	id delegate;
	SEL action;
}
@property (assign) ATWebClientReturnType returnType;
@property (assign) BOOL failed;
@property (copy) NSString *errorTitle;
@property (copy) NSString *errorMessage;
@property (copy) NSString *channelName;
@property (assign) NSTimeInterval timeoutInterval;

- (id)initWithTarget:(id)delegate action:(SEL)action;
- (void)showAlert;
- (void)cancel;

- (void)getContactInfo;
- (void)postFeedback:(ATFeedback *)feedback;

#pragma mark Query Parameter Encoding
- (NSString *)stringForParameters:(NSDictionary *)parameters;
- (NSString *)stringForParameter:(id)value;

#pragma mark Internal Methods
- (void)get:(NSURL *)theURL;
- (void)post:(NSURL *)theURL;
- (void)post:(NSURL *)theURL JSON:(NSString *)body;
- (void)post:(NSURL *)theURL body:(NSString *)body;
- (void)addAPIHeaders:(ATURLConnection *)conn;
- (void)post:(NSURL *)theURL withFileData:(NSData *)data ofMimeType:(NSString *)mimeType parameters:(NSDictionary *)parameters;
@end
