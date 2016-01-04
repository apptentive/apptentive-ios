//
//  ATConnect+Debugging.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/23/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATConnect_Private.h"

typedef NS_OPTIONS(NSInteger, ATConnectDebuggingOptions) {
	ATConnectDebuggingOptionsNone = 0,
	ATConnectDebuggingOptionsShowDebugPanel = 1 << 0,
	ATConnectDebuggingOptionsLogHTTPFailures = 1 << 1,
	ATConnectDebuggingOptionsLogAllHTTPRequests = 1 << 2,
};

NS_ASSUME_NONNULL_BEGIN

@interface ATConnect ()

@property (assign, nonatomic) ATConnectDebuggingOptions debuggingOptions;
@property (readonly, nonatomic) NSURL * _Nullable baseURL;

- (void)setAPIKey:(NSString *)APIKey baseURL:(NSURL *)baseURL;

@end

@interface ATConnect (Debugging)

@property (readonly, nonatomic) NSString *SDKVersion;
@property (readonly, nonatomic) NSString * _Nullable APIKey;
@property (readonly, nonatomic) UIView * _Nullable unreadAccessoryView;
@property (readonly, nonatomic) NSString * _Nullable manifestJSON;
@property (readonly, nonatomic) NSDictionary<NSString *, NSObject *> *deviceInfo;

@property (readonly, nonatomic) NSString *personName;
@property (readonly, nonatomic) NSString *personEmailAddress;

@end

NS_ASSUME_NONNULL_END
