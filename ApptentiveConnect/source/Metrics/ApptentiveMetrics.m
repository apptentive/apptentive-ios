//
//  ApptentiveMetrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetrics.h"

#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveData.h"
#import "ApptentiveEvent.h"
#import "ApptentiveEngagementBackend.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveQueuedRequest.h"

// Engagement event labels

static NSString *ATInteractionAppEventLabelLaunch = @"launch";
static NSString *ATInteractionAppEventLabelExit = @"exit";


@interface ApptentiveMetrics ()

- (void)addLaunchMetric;

- (void)appWillTerminate:(NSNotification *)notification;
- (void)appDidEnterBackground:(NSNotification *)notification;
- (void)appWillEnterForeground:(NSNotification *)notification;

- (void)preferencesChanged:(NSNotification *)notification;
- (void)updateWithCurrentPreferences;

@end


@implementation ApptentiveMetrics {
	BOOL metricsEnabled;
}

+ (ApptentiveMetrics *)sharedMetrics {
	static ApptentiveMetrics *sharedSingleton = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSingleton = [[ApptentiveMetrics alloc] init];
	});
	return sharedSingleton;
}

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo {
	[self addMetricWithName:name info:userInfo customData:nil extendedData:nil];
}

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	[self addMetricWithName:name fromInteraction:nil info:userInfo customData:customData extendedData:extendedData];
}

- (void)addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	if (metricsEnabled == NO) {
		return;
	}

	if (![[NSThread currentThread] isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self addMetricWithName:name fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];
		});
		return;
	}

	ApptentiveEvent *event = [ApptentiveEvent newInstanceWithLabel:name];

	if (fromInteraction) {
		NSString *interactionID = fromInteraction.identifier;
		if (interactionID) {
			[event addEntriesFromDictionary:@{ @"interaction_id": interactionID }];
		}
	}

	if (userInfo) {
		// Surveys and other legacy metrics may pass `interaction_id` as a key in userInfo.
		// We should pull it out and add it to the top level event, rather than as a child of `data`.
		// TODO: Surveys should call `engage:` rather than `addMetric...` so this is not needed.
		NSString *interactionIDFromUserInfo = userInfo[@"interaction_id"];
		if (interactionIDFromUserInfo) {
			[event addEntriesFromDictionary:@{ @"interaction_id": interactionIDFromUserInfo }];

			NSMutableDictionary *userInfoMinusInteractionID = [NSMutableDictionary dictionaryWithDictionary:userInfo];
			[userInfoMinusInteractionID removeObjectForKey:@"interaction_id"];

			[event addEntriesFromDictionary:@{ @"data": userInfoMinusInteractionID }];
		} else {
			[event addEntriesFromDictionary:@{ @"data": userInfo }];
		}
	}

	if (customData) {
		NSDictionary *customDataDictionary = @{ @"custom_data": customData };
		if ([NSJSONSerialization isValidJSONObject:customDataDictionary]) {
			[event addEntriesFromDictionary:customDataDictionary];
		} else {
			ApptentiveLogError(@"Event `customData` cannot be transformed into valid JSON and will be ignored.");
			ApptentiveLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
		}
	}

	if (extendedData) {
		for (NSDictionary *data in extendedData) {
			if ([NSJSONSerialization isValidJSONObject:data]) {
				// Extended data items are not added for key "extended_data", but rather for key of extended data type: "time", "location", etc.
				[event addEntriesFromDictionary:data];
			} else {
				ApptentiveLogError(@"Event `extendedData` cannot be transformed into valid JSON and will be ignored.");
				ApptentiveLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
			}
		}
	}

	[ApptentiveQueuedRequest enqueueRequestWithPath:@"events" method:@"POST" payload:event.apiJSON attachments:nil identifier:nil inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];
}

- (void)backendBecameAvailable:(NSNotification *)notification {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ATBackendBecameReadyNotification object:nil];

		[self updateWithCurrentPreferences];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:ATConfigurationPreferencesChangedNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

		if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
			[self performSelector:@selector(addLaunchMetric) withObject:nil afterDelay:0.1];
		}
	}
}

- (id)init {
	self = [super init];
	if (self) {
		metricsEnabled = NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backendBecameAvailable:) name:ATBackendBecameReadyNotification object:nil];
	}

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (void)addLaunchMetric {
	@autoreleasepool {
		[[Apptentive sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
	}
}

- (void)appWillTerminate:(NSNotification *)notification {
	[[Apptentive sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[[Apptentive sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[[Apptentive sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self updateWithCurrentPreferences];
}

- (void)updateWithCurrentPreferences {
	metricsEnabled = Apptentive.shared.backend.configuration.metricsEnabled;
}

@end
