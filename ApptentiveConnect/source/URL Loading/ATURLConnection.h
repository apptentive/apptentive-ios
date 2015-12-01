//
//  ATURLConnection.h
//
//  Created by Andrew Wooster on 12/14/08.
//  Copyright 2008 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATURLConnectionDelegate;


@interface ATURLConnection : NSObject
@property (nonatomic, readonly, copy) NSURL *targetURL;
@property (nonatomic, weak) NSObject<ATURLConnectionDelegate> *delegate;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, readonly) BOOL cancelled;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSURLCredential *credential;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) BOOL failedAuthentication;
@property (nonatomic, copy) NSError *connectionError;
@property (nonatomic, assign) float percentComplete;
@property (nonatomic, readonly) NSTimeInterval expiresMaxAge;

@property (strong, nonatomic) NSData *HTTPBody;
@property (strong, nonatomic) NSString *HTTPMethod;

/*! The delegate for this class is a weak reference. */
- (id)initWithURL:(NSURL *)url delegate:(NSObject<ATURLConnectionDelegate> *)aDelegate;
- (id)initWithURL:(NSURL *)url;
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)removeHTTPHeaderField:(NSString *)field;

- (void)start;

- (BOOL)isExecuting;
- (BOOL)isCancelled;
- (BOOL)isFinished;
/*! A localized description of the response status code. */
- (NSString *)statusLine;
/*! The response headers. */
- (NSDictionary *)responseHeaders;
- (NSData *)responseData;

/*! The request headers. */
- (NSDictionary *)headers;

#pragma mark Debugging
- (NSString *)requestAsString;
- (NSString *)responseAsString;
@end


@protocol ATURLConnectionDelegate <NSObject>
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender;
- (void)connectionFailed:(ATURLConnection *)sender;
- (void)connectionDidProgress:(ATURLConnection *)sender;
@end
