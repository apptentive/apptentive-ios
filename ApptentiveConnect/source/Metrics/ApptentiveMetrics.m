//
//  ApptentiveMetrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetrics.h"

#import "ATAppConfigurationUpdater.h"
#import "ATBackend.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATEvent.h"
#import "ATMetric.h"
#import "ATRecordTask.h"
#import "ATRecordRequestTask.h"
#import "ATSurveyMetrics.h"
#import "ATTaskQueue.h"
#import "ATEngagementBackend.h"

// Engagement event labels

static NSString *ATInteractionAppEventLabelLaunch = @"launch";
static NSString *ATInteractionAppEventLabelExit = @"exit";

// Legacy metric event labels

static NSString *ATMetricNameSurveyCancel = @"survey.cancel";
static NSString *ATMetricNameSurveySubmit = @"survey.submit";
static NSString *ATMetricNameSurveyAnswerQuestion = @"survey.question_response";


@interface ApptentiveMetrics ()

- (void)addLaunchMetric;

- (ATSurveyEvent)surveyEventTypeFromNotification:(NSNotification *)notification;
- (void)surveyDidHide:(NSNotification *)notification;
- (void)surveyDidAnswerQuestion:(NSNotification *)notification;

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

+ (void)registerDefaults {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultPreferences =
		[NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES], ATAppConfigurationMetricsEnabledPreferenceKey,
					  nil];
	[defaults registerDefaults:defaultPreferences];
}

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo {
	[self addMetricWithName:name info:userInfo customData:nil extendedData:nil];
}

- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	[self addMetricWithName:name fromInteraction:nil info:userInfo customData:customData extendedData:extendedData];
}

- (void)addMetricWithName:(NSString *)name fromInteraction:(ATInteraction *)fromInteraction info:(NSDictionary *)userInfo customData:(NSDictionary *)customData extendedData:(NSArray *)extendedData {
	if (metricsEnabled == NO) {
		return;
	}

	if (![[NSThread currentThread] isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self addMetricWithName:name fromInteraction:fromInteraction info:userInfo customData:customData extendedData:extendedData];
		});
		return;
	}

	ATEvent *event = [ATEvent newInstanceWithLabel:name];

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
			ATLogError(@"Event `customData` cannot be transformed into valid JSON and will be ignored.");
			ATLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
		}
	}

	if (extendedData) {
		for (NSDictionary *data in extendedData) {
			if ([NSJSONSerialization isValidJSONObject:data]) {
				// Extended data items are not added for key "extended_data", but rather for key of extended data type: "time", "location", etc.
				[event addEntriesFromDictionary:data];
			} else {
				ATLogError(@"Event `extendedData` cannot be transformed into valid JSON and will be ignored.");
				ATLogError(@"Please see NSJSONSerialization's `+isValidJSONObject:` for allowed types.");
			}
		}
	}

	if (![ATData save]) {
		event = nil;
		return;
	}

	ATRecordRequestTask *task = [[ATRecordRequestTask alloc] init];
	[task setTaskProvider:event];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	event = nil;
	task = nil;
}

- (void)backendBecameAvailable:(NSNotification *)notification {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ATBackendBecameReadyNotification object:nil];

		[ApptentiveMetrics registerDefaults];
		[self updateWithCurrentPreferences];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidHide:) name:ATSurveyDidHideWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(surveyDidAnswerQuestion:) name:ATSurveyDidAnswerQuestionNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:ATConfigurationPreferencesChangedNotification object:nil];

#if TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
#elif TARGET_OS_MAC
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
		[self performSelector:@selector(addLaunchMetric) withObject:nil afterDelay:0.1];
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

- (BOOL)upgradeLegacyMetric:(ATMetric *)metric {
	if (metricsEnabled == NO) {
		return NO;
	}

	ATEvent *event = [ATEvent newInstanceWithLabel:metric.name];
	[event addEntriesFromDictionary:[metric info]];
	if (![ATData save]) {
		event = nil;
		return NO;
	}

	ATRecordRequestTask *task = [[ATRecordRequestTask alloc] init];
	[task setTaskProvider:event];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	event = nil;
	task = nil;
	return YES;
}

#pragma mark - Private methods

- (void)addLaunchMetric {
	@autoreleasepool {
		[[ATConnect sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
	}
}

- (ATSurveyEvent)surveyEventTypeFromNotification:(NSNotification *)notification {
	ATSurveyEvent event = ATSurveyEventUnknown;
	if ([[notification userInfo] objectForKey:ATSurveyMetricsEventKey]) {
		event = [(NSNumber *)[[notification userInfo] objectForKey:ATSurveyMetricsEventKey] intValue];
	}
	if (event != ATSurveyEventTappedSend && event != ATSurveyEventTappedCancel && event != ATSurveyEventAnsweredQuestion) {
		event = ATSurveyEventUnknown;
		ATLogError(@"Unknown survey event type: %d", event);
	}
	return event;
}

- (void)surveyDidHide:(NSNotification *)notification {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

	NSString *surveyID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyIDKey];
	if (surveyID != nil) {
		[info setObject:surveyID forKey:@"id"];
	}

	NSString *surveyInteractionID = [[notification userInfo] objectForKey:@"interaction_id"];
	if (surveyInteractionID) {
		info[@"interaction_id"] = surveyInteractionID;
	}

	ATSurveyEvent eventType = [self surveyEventTypeFromNotification:notification];

	if (eventType == ATSurveyEventTappedSend) {
		[self addMetricWithName:ATMetricNameSurveySubmit info:info];
	} else if (eventType == ATSurveyEventTappedCancel) {
		[self addMetricWithName:ATMetricNameSurveyCancel info:info];
	}

	info = nil;
}

- (void)surveyDidAnswerQuestion:(NSNotification *)notification {
	NSMutableDictionary *info = [[NSMutableDictionary alloc] init];

	NSString *surveyID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyIDKey];
	if (surveyID != nil) {
		[info setObject:surveyID forKey:@"survey_id"];
	}

	NSString *questionID = [[notification userInfo] objectForKey:ATSurveyMetricsSurveyQuestionIDKey];
	if (questionID != nil) {
		[info setObject:questionID forKey:@"id"];
	}

	NSString *surveyInteractionID = [[notification userInfo] objectForKey:@"interaction_id"];
	if (surveyInteractionID) {
		info[@"interaction_id"] = surveyInteractionID;
	}

	ATSurveyEvent eventType = [self surveyEventTypeFromNotification:notification];
	if (eventType == ATSurveyEventAnsweredQuestion) {
		[self addMetricWithName:ATMetricNameSurveyAnswerQuestion info:info];
	}

	info = nil;
}

- (void)appWillTerminate:(NSNotification *)notification {
	[[ATConnect sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appDidEnterBackground:(NSNotification *)notification {
	[[ATConnect sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelExit];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
	[[ATConnect sharedConnection].engagementBackend engageApptentiveAppEvent:ATInteractionAppEventLabelLaunch];
}

- (void)preferencesChanged:(NSNotification *)notification {
	[self updateWithCurrentPreferences];
}

- (void)updateWithCurrentPreferences {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSNumber *enabled = [defaults objectForKey:ATAppConfigurationMetricsEnabledPreferenceKey];
	if (enabled != nil) {
		metricsEnabled = [enabled boolValue];
	}
}
@end
