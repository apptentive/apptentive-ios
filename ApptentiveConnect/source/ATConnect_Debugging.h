//
//  ATConnect_Debugging.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/23/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ATConnect.h"

typedef NS_OPTIONS(NSInteger, ATConnectDebuggingOptions) {
	ATConnectDebuggingOptionsNone = 0,
	ATConnectDebuggingOptionsShowDebugPanel = 1 << 0,
	ATConnectDebuggingOptionsLogHTTPFailures = 1 << 1,
	ATConnectDebuggingOptionsLogAllHTTPRequests = 1 << 2,
};

@interface ATConnect ()
@property (nonatomic, assign) ATConnectDebuggingOptions debuggingOptions;
@end
