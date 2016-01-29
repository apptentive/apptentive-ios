//
//  ATDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATDeviceUpdater.h"
#import "ATUtilities.h"
#import "ATWebClient+MessageCenter.h"
#import "ATConnect_Private.h"
#import "ATBackend.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";


@interface ATDeviceUpdater ()

@property (strong, nonatomic) NSDictionary *sentDeviceJSON;
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

	ATDeviceInfo *deviceInfo = [ATConnect sharedConnection].backend.currentDevice;
	NSDictionary *deviceDictionary = [deviceInfo.apiJSON valueForKey:@"device"];

	return deviceDictionary.count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey];
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
	ATDeviceInfo *deviceInfo = [ATConnect sharedConnection].backend.currentDevice;
	self.sentDeviceJSON = deviceInfo.dictionaryRepresentation;
	self.request = [[ATConnect sharedConnection].webClient requestForUpdatingDevice:deviceInfo];
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
	@synchronized(self) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

		[defaults setObject:[NSDate date] forKey:ATDeviceLastUpdatePreferenceKey];
		[defaults setObject:self.sentDeviceJSON forKey:ATDeviceLastUpdateValuePreferenceKey];
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
