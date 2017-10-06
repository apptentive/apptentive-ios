//
//  ApptentiveReachability.h
//  Apptentive
//
//  Created by Andrew Wooster on 4/13/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
	ApptentiveNetworkNotReachable,
	ApptentiveNetworkWifiReachable,
	ApptentiveNetworkWWANReachable
} ApptentiveNetworkStatus;

extern NSString *const ApptentiveReachabilityStatusChanged;


@interface ApptentiveReachability : NSObject

- (instancetype)initWithHostname:(NSString *)hostname;
- (ApptentiveNetworkStatus)currentNetworkStatus;

@end

NS_ASSUME_NONNULL_END
