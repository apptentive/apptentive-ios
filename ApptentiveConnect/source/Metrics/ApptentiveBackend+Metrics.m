//
//  ApptentiveMetrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveBackend+Metrics.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveAppConfiguration.h"
#import "ApptentiveSerialRequest+Record.h"

// Engagement event labels

static NSString *ATInteractionAppEventLabelLaunch = @"launch";
static NSString *ATInteractionAppEventLabelExit = @"exit";

@implementation ApptentiveBackend (Metrics)

- (void)addMetricWithName:(NSString *)name fromInteraction:(ApptentiveInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	if (self.configuration.metricsEnabled == NO || name == nil) {
		return;
	}

	[ApptentiveSerialRequest enqueueEventWithLabel:name interactionIdentifier:fromInteraction.identifier userInfo:userInfo customData:customData extendedData:extendedData inContext:Apptentive.shared.backend.managedObjectContext];

	[self processQueuedRecords];
}

- (void)startMonitoringAppLifecycleMetrics {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

	if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
		[self addLaunchMetric];
	}
}

#pragma mark - Private methods

- (void)addLaunchMetric {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)appWillTerminate:(NSNotification *)notification {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[self engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

@end
