//
//  ATDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceUpdater.h"

#import "ATWebClient+MessageCenter.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";

// Interval, in seconds, after which we'll update the device.
#if APPTENTIVE_DEBUG
#	define kATDeviceUpdateInterval (3)
#else
#	define kATDeviceUpdateInterval (60*60*24*7)
#endif

@implementation ATDeviceUpdater
@synthesize delegate;
+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATDeviceLastUpdatePreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldUpdate {
	[ATDeviceUpdater registerDefaults];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastCheck = [defaults objectForKey:ATDeviceLastUpdatePreferenceKey];
		
#ifndef APPTENTIVE_DEBUG
	NSDate *expiration = [defaults objectForKey:ATDeviceLastUpdatePreferenceKey];
	if (expiration) {
		NSDate *now = [NSDate date];
		NSComparisonResult comparison = [expiration compare:now];
		if (comparison == NSOrderedSame || comparison == NSOrderedAscending) {
			return YES;
		} else {
			return NO;
		}
	}
#endif
	
	// Fall back to the defaults.
	NSTimeInterval interval = [lastCheck timeIntervalSinceNow];
	
	if (interval <= -kATDeviceUpdateInterval) {
		return YES;
	} else {
		return NO;
	}
}

- (id)initWithDelegate:(NSObject<ATDeviceUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	delegate = nil;
	[self cancel];
	[super dealloc];
}

- (void)update {
	[self cancel];
	ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
	request = [[[ATWebClient sharedClient] requestForUpdatingDevice:deviceInfo] retain];
	request.delegate = self;
	[request start];
	[deviceInfo release], deviceInfo = nil;
}

- (void)cancel {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
	}
}

- (float)percentageComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		[delegate deviceUpdater:self didFinish:YES];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[delegate deviceUpdater:self didFinish:NO];
	}
}

@end
