//
//  ATAPIRequest.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATURLConnection.h"

extern NSString *const ATAPIRequestStatusChanged;

@class ATAPIRequest;

typedef enum {
	ATAPIRequestReturnTypeData,
	ATAPIRequestReturnTypeString,
	ATAPIRequestReturnTypeJSON
} ATAPIRequestReturnType;

@protocol ATAPIRequestDelegate <NSObject>
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(NSObject *)result;
- (void)at_APIRequestDidFail:(ATAPIRequest *)request;
@optional
- (void)at_APIRequestDidProgress:(ATAPIRequest *)request;
@end

/*! API request for the apptentive.com service. Encapsulates the connection
 connection state, completion percentage, etc. */
@interface ATAPIRequest : NSObject <ATURLConnectionDelegate>

@property (readonly, nonatomic) BOOL failed;
@property (readonly, nonatomic) BOOL shouldRetry;
@property (readonly, nonatomic) NSString *errorTitle;
@property (readonly, nonatomic) NSString *errorMessage;
@property (readonly, nonatomic) NSString *errorResponse;
@property (readonly, nonatomic) float percentageComplete;
@property (readonly, nonatomic) NSTimeInterval expiresMaxAge;

@property (assign, nonatomic) ATAPIRequestReturnType returnType;
@property (assign, nonatomic) NSTimeInterval timeoutInterval;
@property (weak, nonatomic) NSObject<ATAPIRequestDelegate> *delegate;

- (id)initWithConnection:(ATURLConnection *)connection channelName:(NSString *)channelName;
- (void)start;
- (void)cancel;
- (void)showAlert;

@end
