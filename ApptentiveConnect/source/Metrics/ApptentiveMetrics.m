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
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveSerialRequest+Record.h"

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
	if (metricsEnabled == NO || name == nil) {
		return;
	}

	[ApptentiveSerialRequest enqueueEventWithLabel:name interactionIdentifier:fromInteraction.identifier userInfo:userInfo customData:customData extendedData:extendedData inContext:Apptentive.shared.backend.managedObjectContext];

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
		[Apptentive.shared.backend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
	}
}

- (void)appWillTerminate:(NSNotification *)notification {
	[Apptentive.shared.backend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[Apptentive.shared.backend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[Apptentive.shared.backend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self updateWithCurrentPreferences];
}

- (void)updateWithCurrentPreferences {
	metricsEnabled = Apptentive.shared.backend.configuration.metricsEnabled;
}

@end
