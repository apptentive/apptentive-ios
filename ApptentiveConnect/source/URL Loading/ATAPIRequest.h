//
//  ATAPIRequest.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const ATAPIRequestStatusChanged;

@class ATURLConnection;
@class ATAPIRequest;

typedef enum {
	ATAPIRequestReturnTypeData,
	ATAPIRequestReturnTypeString
#ifdef SUPPORT_JSON
    ,
	ATAPIRequestReturnTypeJSON
#endif
} ATAPIRequestReturnType;

@protocol ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)request result:(id)result;
- (void)at_APIRequestDidProgress:(ATAPIRequest *)request;
- (void)at_APIRequestDidFail:(ATAPIRequest *)request;
@end

/*! API request for the apptentive.com service. Encapsulates the connection
 connection state, completion percentage, etc. */
@interface ATAPIRequest : NSObject {
@private
    ATURLConnection *connection;
    NSString *channelName;
    BOOL cancelled;
    float percentageComplete;
}
@property (nonatomic, assign) ATAPIRequestReturnType returnType;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, retain) NSString *errorTitle;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, retain) id <ATAPIRequestDelegate> delegate;

- (id)initWithConnection:(ATURLConnection *)connection channelName:(NSString *)channelName;
- (void)start;
- (void)cancel;
- (void)showAlert;
- (float)percentageComplete;
@end

