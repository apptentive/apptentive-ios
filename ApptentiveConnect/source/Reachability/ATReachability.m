//
//  ATReachability.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/13/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATReachability.h"
#import "ATUtilities.h"
#import "ATLog.h"

NSString *const ATReachabilityStatusChanged = @"ATReachabilityStatusChanged";

@interface ATReachability (Private)
- (BOOL)start;
- (void)stop;
@end


@implementation ATReachability
+ (ATReachability *)sharedReachability {
	static ATReachability *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ATReachability alloc] init];
	});
	return sharedSingleton;
}

- (id)init {
	if ((self = [super init])) {
		SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [kApptentiveHostName UTF8String]);
		if (reachability != NULL) {
			reachabilityRef = reachability;
			[self start];
		}
	}
	return self;
}

static void ATReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
	@autoreleasepool {
		if (info == NULL) return;
		if (![(NSObject *)info isKindOfClass:[ATReachability class]]) return;
		
		ATReachability *reachability = (ATReachability *)info;
		
		[[ATReachability sharedReachability] updateDeviceInfoWithCurrentNetworkType:reachability];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ATReachabilityStatusChanged object:reachability];
	}
}

- (void)updateDeviceInfoWithCurrentNetworkType:(ATReachability *)reachability {
	//TODO: ATDeviceInfo is not currently being updated with the new network type.
	ATNetworkStatus status = [reachability currentNetworkStatus];
	
	NSString *statusString = @"network not reachable";
	if (status == ATNetworkWifiReachable) {
		statusString = @"WiFi";
	} else if (status == ATNetworkWWANReachable) {
		statusString = @"WWAN";
	}
	ATLogInfo(@"Apptentive Reachability changed: %@", statusString);
}

- (void)dealloc {
	[self stop];
	if (reachabilityRef != NULL) {
		CFRelease(reachabilityRef);
		reachabilityRef = NULL;
	}
	[super dealloc];
}

- (ATNetworkStatus)currentNetworkStatus {
	ATNetworkStatus status = ATNetworkNotReachable;
	
	do { // once
		if (reachabilityRef == NULL) {
			break;
		}
		
		SCNetworkReachabilityFlags flags;
		
		if (!SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
			break;
		}
		
		if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
			break;
		}
		
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
			status = ATNetworkWifiReachable;
		}
		
		BOOL onDemand = ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0);
		BOOL onTraffic = ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0);
		BOOL interventionRequired = ((flags & kSCNetworkReachabilityFlagsInterventionRequired) != 0);
		
		if ((onDemand || onTraffic) && !interventionRequired) {
			status = ATNetworkWifiReachable;
		}
#if TARGET_OS_IPHONE
		BOOL isWWAN = ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN);
		if (isWWAN) {
			status = ATNetworkWWANReachable;
		}
#endif
	} while (NO);
	
	return status;
}
@end


@implementation ATReachability (Private)
- (BOOL)start {
	BOOL result = NO;
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	do { // once
		if (!SCNetworkReachabilitySetCallback(reachabilityRef, ATReachabilityCallback, &context)) {
			break;
		}
		
		if (!SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
			break;
		}
		
		result = YES;
	} while (NO);
	
	return result;
}

- (void)stop {
	if (reachabilityRef != NULL) {
		SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	}
}
@end
