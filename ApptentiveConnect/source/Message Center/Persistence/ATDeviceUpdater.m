//
//  ATDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceUpdater.h"

#import "ATConversationUpdater.h"
#import "ATUtilities.h"
#import "ATWebClient+MessageCenter.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";

@interface ATDeviceUpdater ()

@property (strong, nonatomic) ATAPIRequest *request;

@end

@implementation ATDeviceUpdater

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSDate distantPast], ATDeviceLastUpdatePreferenceKey,
	 [NSDictionary dictionary], ATDeviceLastUpdateValuePreferenceKey,
	 nil];
	[defaults registerDefaults:defaultPreferences];
}

+ (BOOL)shouldUpdate {
	[ATDeviceUpdater registerDefaults];
	
	if (![ATConversationUpdater conversationExists]) {
		return NO;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSObject *lastValue = [defaults objectForKey:ATDeviceLastUpdateValuePreferenceKey];
	BOOL shouldUpdate = NO;
	if (lastValue == nil || ![lastValue isKindOfClass:[NSDictionary class]]) {
		shouldUpdate = YES;
	} else {
		NSDictionary *lastValueDictionary = (NSDictionary *)lastValue;
		ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
		NSDictionary *currentValueDictionary = [deviceInfo apiJSON];
		deviceInfo = nil;
		if (![ATUtilities dictionary:currentValueDictionary isEqualToDictionary:lastValueDictionary]) {
			shouldUpdate = YES;
		}
	}
	
	return shouldUpdate;
}

- (id)initWithDelegate:(NSObject<ATDeviceUpdaterDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	_delegate = nil;
	[self cancel];
}

- (void)update {
	[self cancel];
	ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
	self.request = [[ATWebClient sharedClient] requestForUpdatingDevice:deviceInfo];
	self.request.delegate = self;
	[self.request start];
	deviceInfo = nil;
}

- (void)cancel {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
	}
}

- (float)percentageComplete {
	if (self.request) {
		return [self.request percentageComplete];
	} else {
		return 0.0f;
	}
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized (self) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		ATDeviceInfo *deviceInfo = [[ATDeviceInfo alloc] init];
		NSDictionary *currentValueDictionary = [deviceInfo apiJSON];
		deviceInfo = nil;
		
		[defaults setObject:[NSDate date] forKey:ATDeviceLastUpdatePreferenceKey];
		[defaults setObject:currentValueDictionary forKey:ATDeviceLastUpdateValuePreferenceKey];
		[self.delegate deviceUpdater:self didFinish:YES];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		ATLogInfo(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
		
		[self.delegate deviceUpdater:self didFinish:NO];
	}
}

@end
