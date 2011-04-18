//
//  ATURLConnection.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATURLConnection : NSObject {
	NSURL *targetURL;
	id delegate;
	
	NSURLConnection *connection;
	NSMutableData *data;
	BOOL executing;
	BOOL finished;
	BOOL failed;
	BOOL cancelled;
	NSTimeInterval timeoutInterval;
	NSURLCredential *credential;
	
	NSMutableDictionary *headers;
	NSString *HTTPMethod;
	NSData *HTTPBody;
	
	int statusCode;
	BOOL failedAuthentication;
	NSError *connectionError;
}
@property (nonatomic, readonly, copy) NSURL *targetURL;
@property (nonatomic, readonly) id delegate;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, retain) NSURLCredential *credential;
@property (nonatomic, readonly) int statusCode;
@property (nonatomic, readonly) BOOL failedAuthentication;
@property (nonatomic, copy) NSError *connectionError;

/*! The delegate for this class is a weak reference. */
- (id)initWithURL:(NSURL *)url delegate:(id)aDelegate;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setHTTPMethod:(NSString *)method;
- (void)setHTTPBody:(NSData *)body;

- (void) start;
- (void) cancel;

- (BOOL)isExecuting;
- (BOOL)isCancelled;
- (BOOL)isFinished;

- (NSData *)responseData;
@end


@protocol ATURLConnectionDelegate
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender;
- (void)connectionFailed:(ATURLConnection *)sender;
@end
