//
//  ApptentiveDeviceUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDeviceUpdater.h"

#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveQueuedRequest.h"
#import "ApptentiveData.h"
#import "ApptentiveDeviceInfo.h"
#import "ApptentiveBackend.h"


NSString *const ATDeviceLastUpdatePreferenceKey = @"ATDeviceLastUpdatePreferenceKey";
NSString *const ATDeviceLastUpdateValuePreferenceKey = @"ATDeviceLastUpdateValuePreferenceKey";


@implementation ApptentiveDeviceUpdater

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
	[ApptentiveDeviceUpdater registerDefaults];

	ApptentiveDeviceInfo *deviceInfo = [[ApptentiveDeviceInfo alloc] init];
	NSDictionary *deviceDictionary = [deviceInfo.apiJSON valueForKey:@"device"];

	return deviceDictionary.count > 0;
}

+ (NSDictionary *)lastSavedVersion {
	return [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey];
}

+ (void)resetDeviceInfo {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATDeviceLastUpdatePreferenceKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATDeviceLastUpdateValuePreferenceKey];
}

- (void)update {
	ApptentiveDeviceInfo *deviceInfo = [[ApptentiveDeviceInfo alloc] init];


	[ApptentiveQueuedRequest enqueueRequestWithPath:@"devices" payload:deviceInfo.apiJSON attachments:nil inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];

	[[NSUserDefaults standardUserDefaults] setObject:deviceInfo.dictionaryRepresentation forKey:ATDeviceLastUpdateValuePreferenceKey];
}

@end
