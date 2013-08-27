//
//  ATSurveysBackend.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveysBackend.h"
#import "ATBackend.h"
#import "ATSurvey.h"
#import "ATSurveyGetSurveyTask.h"
#import "ATSurveyMetrics.h"
#import "ATSurveys.h"
#import "ATSurveyParser.h"
#import "ATSurveyViewController.h"
#import "ATTaskQueue.h"
#import "PJSONKit.h"

NSString *const ATSurveySentSurveysPreferenceKey = @"ATSurveySentSurveysPreferenceKey";


@implementation ATSurveysBackend

+ (ATSurveysBackend *)sharedBackend {
	static ATSurveysBackend *sharedBackend = nil;
	@synchronized(self) {
		if (sharedBackend == nil) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			NSDictionary *defaultPreferences = [NSDictionary dictionaryWithObject:[NSArray array] forKey:ATSurveySentSurveysPreferenceKey];
			[defaults registerDefaults:defaultPreferences];
			
			sharedBackend = [[ATSurveysBackend alloc] init];
		}
	}
	return sharedBackend;
}

- (void)dealloc {
	[super dealloc];
}

- (void)checkForAvailableSurveys {
	ATSurveyGetSurveyTask *task = [[ATSurveyGetSurveyTask alloc] init];
	[[ATTaskQueue sharedTaskQueue] addTask:task];
	[task release], task = nil;
}

- (ATSurvey *)currentSurvey {
	return currentSurvey;
}

- (void)resetSurvey {
	[currentSurvey release], currentSurvey = nil;
}

- (void)presentSurveyControllerFromViewController:(UIViewController *)viewController {
	if (currentSurvey == nil) {
		return;
	}
	ATSurveyViewController *vc = [[ATSurveyViewController alloc] initWithSurvey:currentSurvey];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[viewController presentModalViewController:nc animated:YES];
	} else {
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
		[viewController presentModalViewController:nc animated:YES];
	}
	[nc release];
	[vc release];
	
	NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:currentSurvey.identifier, ATSurveyMetricsSurveyIDKey, [NSNumber numberWithInt:ATSurveyWindowTypeSurvey], ATSurveyWindowTypeKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidShowWindowNotification object:nil userInfo:metricsInfo];
	[metricsInfo release], metricsInfo = nil;
}

- (void)setDidSendSurvey:(ATSurvey *)survey {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *sentSurveys = [defaults objectForKey:ATSurveySentSurveysPreferenceKey];
	if (![sentSurveys containsObject:survey.identifier]) {
		NSMutableArray *replacementSurveys = [sentSurveys mutableCopy];
		[replacementSurveys addObject:survey.identifier];
		[defaults setObject:replacementSurveys forKey:ATSurveySentSurveysPreferenceKey];
		[defaults synchronize];
		[replacementSurveys release], replacementSurveys = nil;
	}
}

@end


@implementation ATSurveysBackend (Private)
- (BOOL)surveyAlreadySubmitted:(ATSurvey *)survey {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL sentSurvey = NO;
	if ([[defaults objectForKey:ATSurveySentSurveysPreferenceKey] containsObject:survey.identifier]) {
		sentSurvey = YES;
	}
	return sentSurvey;
}

- (void)didReceiveNewSurvey:(ATSurvey *)survey {
	if (![self surveyAlreadySubmitted:survey]) {
		[currentSurvey release], currentSurvey = nil;
		currentSurvey = [survey retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyNewSurveyAvailableNotification object:nil];
	}
}
@end
