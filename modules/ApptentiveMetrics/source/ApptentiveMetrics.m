//
//  ApptentiveMetrics.m
//  ApptentiveMetrics
//
//  Created by Andrew Wooster on 12/27/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveMetrics.h"
#import "ATFeedbackMetrics.h"
#import "ATAppRatingMetrics.h"
#import "ATMetric.h"
#import "ATRecordTask.h"
#import "ATTaskQueue.h"

static NSString *ATMetricNameEnjoymentDialogLaunch = @"enjoyment_dialog.launch";
static NSString *ATMetricNameEnjoymentDialogYes = @"enjoyment_dialog.yes";
static NSString *ATMetricNameEnjoymentDialogNo = @"enjoyment_dialog.no";

static NSString *ATMetricNameRatingDialogLaunch = @"rating_dialog.launch";
static NSString *ATMetricNameRatingDialogRate = @"rating_dialog.rate";
static NSString *ATMetricNameRatingDialogRemind = @"rating_dialog.remind";
static NSString *ATMetricNameRatingDialogDecline = @"rating_dialog.decline";

static NSString *ATMetricNameFeedbackDialogLaunch = @"feedback_dialog.launch";
static NSString *ATMetricNameFeedbackDialogCancel = @"feedback_dialog.cancel";

static NSString *ATMetricNameAppLaunch = @"app.launch";
static NSString *ATMetricNameAppExit = @"app.exit";

@interface ApptentiveMetrics (Private)
- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo;
- (ATFeedbackWindowType)windowTypeFromNotification:(NSNotification *)notification;
- (void)feedbackDidShowWindow:(NSNotification *)notification;
- (void)feedbackDidHideWindow:(NSNotification *)notification;

- (ATAppRatingEnjoymentButtonType)appEnjoymentButtonTypeFromNotification:(NSNotification *)notification;
- (void)ratingDidShowEnjoyment:(NSNotification *)notification;
- (void)ratingDidClickEnjoyment:(NSNotification *)notification;

- (ATAppRatingButtonType)appRatingButtonTypeFromNotification:(NSNotification *)notification;
- (void)ratingDidShowRating:(NSNotification *)notification;
- (void)ratingDidClickRating:(NSNotification *)notification;
@end

@implementation ApptentiveMetrics
+ (void)load {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:[ApptentiveMetrics class] selector:@selector(sharedMetrics) name:UIApplicationDidFinishLaunchingNotification object:nil];
	[pool release], pool = nil;
}

+ (id)sharedMetrics {
	static ApptentiveMetrics *sharedSingleton = nil;
	@synchronized(self) {
		[[NSNotificationCenter defaultCenter] removeObserver:[ApptentiveMetrics class] name:UIApplicationDidFinishLaunchingNotification object:nil];
		if (sharedSingleton == nil) {
			sharedSingleton = [[ApptentiveMetrics alloc] init];
		}
	}
	return sharedSingleton;
}

- (id)init {
	self = [super init];
	if (self) {
		[self addMetricWithName:ATMetricNameAppLaunch info:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackDidShowWindow:) name:ATFeedbackDidShowWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(feedbackDidHideWindow:) name:ATFeedbackDidHideWindowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidShowEnjoyment:) name:ATAppRatingDidPromptForEnjoymentNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidClickEnjoyment:) name:ATAppRatingDidClickEnjoymentButtonNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidShowRating:) name:ATAppRatingDidPromptForRatingNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingDidClickRating:) name:ATAppRatingDidClickRatingButtonNotification object:nil];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end



@implementation ApptentiveMetrics (Private)
- (void)addMetricWithName:(NSString *)name info:(NSDictionary *)userInfo {
	ATMetric *metric = [[ATMetric alloc] init];
	metric.name = name;
	[metric addEntriesFromDictionary:userInfo];
	ATRecordTask *task = [[ATRecordTask alloc] init];
	[task setRecord:metric];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[metric release], metric = nil;
	[task release], task = nil;
}

- (ATFeedbackWindowType)windowTypeFromNotification:(NSNotification *)notification {
	ATFeedbackWindowType windowType = ATFeedbackWindowTypeFeedback;
	if ([[notification userInfo] objectForKey:ATFeedbackWindowTypeKey]) {
		windowType = [(NSNumber *)[[notification userInfo] objectForKey:ATFeedbackWindowTypeKey] intValue];
	}
	if (windowType != ATFeedbackWindowTypeFeedback && windowType != ATFeedbackWindowTypeInfo) {
		NSLog(@"Unknown window type: %d", windowType);
	}
	return windowType;
}

- (void)feedbackDidShowWindow:(NSNotification *)notification {
	NSString *name = nil;
	ATFeedbackWindowType windowType = [self windowTypeFromNotification:notification];
	
	if (windowType == ATFeedbackWindowTypeFeedback) {
		name = ATMetricNameFeedbackDialogLaunch;
	} else if (windowType == ATFeedbackWindowTypeInfo) {
		name = nil;
	}
	
	if (name != nil) {
		[self addMetricWithName:name info:nil];
	}
}

- (void)feedbackDidHideWindow:(NSNotification *)notification {
	NSString *name = nil;
	ATFeedbackWindowType windowType = [self windowTypeFromNotification:notification];
	ATFeedbackEvent event = ATFeedbackEventTappedCancel;
	if ([[notification userInfo] objectForKey:ATFeedbackWindowHideEventKey]) {
		event = [(NSNumber *)[[notification userInfo] objectForKey:ATFeedbackWindowHideEventKey] intValue];
	}
	
	if (windowType == ATFeedbackWindowTypeFeedback) {
		name = ATMetricNameFeedbackDialogCancel;
	} else if (windowType == ATFeedbackWindowTypeInfo) {
		name = nil;
	}
	
	if (name != nil && event == ATFeedbackEventTappedCancel) {
		[self addMetricWithName:name info:nil];
	}
}

- (ATAppRatingEnjoymentButtonType)appEnjoymentButtonTypeFromNotification:(NSNotification *)notification {
	ATAppRatingEnjoymentButtonType buttonType = ATAppRatingEnjoymentButtonTypeUnknown;
	if ([[notification userInfo] objectForKey:ATAppRatingButtonTypeKey]) {
		buttonType = [(NSNumber *)[[notification userInfo] objectForKey:ATAppRatingButtonTypeKey] intValue];
	}
	if (buttonType != ATAppRatingEnjoymentButtonTypeYes && buttonType != ATAppRatingEnjoymentButtonTypeNo) {
		NSLog(@"Unknown button type: %d", buttonType);
	}
	return buttonType;
}

- (void)ratingDidShowEnjoyment:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameEnjoymentDialogLaunch info:nil];
}

- (void)ratingDidClickEnjoyment:(NSNotification *)notification {
	ATAppRatingEnjoymentButtonType buttonType = [self appEnjoymentButtonTypeFromNotification:notification];
	if (buttonType == ATAppRatingEnjoymentButtonTypeYes) {
		[self addMetricWithName:ATMetricNameEnjoymentDialogYes info:nil];
	} else if (buttonType == ATAppRatingEnjoymentButtonTypeNo) {
		[self addMetricWithName:ATMetricNameEnjoymentDialogNo info:nil];
	}
}

- (ATAppRatingButtonType)appRatingButtonTypeFromNotification:(NSNotification *)notification {
	ATAppRatingButtonType buttonType = ATAppRatingButtonTypeUnknown;
	if ([[notification userInfo] objectForKey:ATAppRatingButtonTypeKey]) {
		buttonType = [(NSNumber *)[[notification userInfo] objectForKey:ATAppRatingButtonTypeKey] intValue];
	}
	if (buttonType != ATAppRatingButtonTypeNo && buttonType != ATAppRatingButtonTypeRemind && buttonType != ATAppRatingButtonTypeRateApp) {
		NSLog(@"Unknown button type: %d", buttonType);
	}
	return buttonType;
}

- (void)ratingDidShowRating:(NSNotification *)notification {
	[self addMetricWithName:ATMetricNameRatingDialogLaunch info:nil];
}

- (void)ratingDidClickRating:(NSNotification *)notification {
	ATAppRatingButtonType buttonType = [self appRatingButtonTypeFromNotification:notification];
	NSString *name = nil;
	if (buttonType == ATAppRatingButtonTypeNo) {
		name = ATMetricNameRatingDialogDecline;
	} else if (buttonType == ATAppRatingButtonTypeRateApp) {
		name = ATMetricNameRatingDialogRate;
	} else if (buttonType == ATAppRatingButtonTypeRemind) {
		name = ATMetricNameRatingDialogRemind;
	}
	if (name != nil) {
		[self addMetricWithName:name info:nil];
	}
}
@end
