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
#import "ATSurveyMetrics.h"
#import "ATSurveyParser.h"
#import "ATSurveyViewController.h"
#import "ATTaskQueue.h"

NSString *const ATSurveySentSurveysPreferenceKey = @"ATSurveySentSurveysPreferenceKey";
NSString *const ATSurveyCachedSurveysExpirationPreferenceKey = @"ATSurveyCachedSurveysExpirationPreferenceKey";

NSString *const ATSurveyNewSurveyAvailableNotification = @"ATSurveyNewSurveyAvailableNotification";
NSString *const ATSurveySentNotification = @"ATSurveySentNotification";

NSString *const ATSurveyIDKey = @"ATSurveyIDKey";

@interface ATSurveysBackend ()
+ (NSString *)cachedSurveysStoragePath;
- (void)presentSurveyControllerFromViewControllerWithCurrentSurvey:(UIViewController *)viewController;
- (ATSurvey *)surveyWithTags:(NSSet *)tags;
@end

@implementation ATSurveysBackend

+ (ATSurveysBackend *)sharedBackend {
	static ATSurveysBackend *sharedBackend = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *defaultPreferences = [NSDictionary dictionaryWithObject:[NSArray array] forKey:ATSurveySentSurveysPreferenceKey];
		[defaults registerDefaults:defaultPreferences];
		
		sharedBackend = [[ATSurveysBackend alloc] init];
	});
	return sharedBackend;
}

+ (NSString *)cachedSurveysStoragePath {
	return [[[ATBackend sharedBackend] supportDirectoryPath] stringByAppendingPathComponent:@"cachedsurveys.objects"];
}

- (id)init {
	if ((self = [super init])) {
		availableSurveys = [[NSMutableArray alloc] init];
		NSFileManager *fm = [NSFileManager defaultManager];
		if ([fm fileExistsAtPath:[ATSurveysBackend cachedSurveysStoragePath]]) {
			@try {
				NSArray *surveys = [NSKeyedUnarchiver unarchiveObjectWithFile:[ATSurveysBackend cachedSurveysStoragePath]];
				[availableSurveys addObjectsFromArray:surveys];
			} @catch (NSException *exception) {
				ATLogError(@"Unable to unarchive surveys: %@", exception);
			}
		}
	}
	return self;
}

- (void)dealloc {
	[availableSurveys release], availableSurveys = nil;
	[super dealloc];
}


- (ATSurvey *)currentSurvey {
	return currentSurvey;
}

- (void)resetSurvey {
	@synchronized(self) {
		[currentSurvey reset];
		[currentSurvey release], currentSurvey = nil;
	}
}

- (void)presentSurveyControllerFromViewControllerWithCurrentSurvey:(UIViewController *)viewController {
	ATSurveyViewController *vc = [[ATSurveyViewController alloc] initWithSurvey:currentSurvey];
	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		nc.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[viewController presentViewController:nc animated:YES completion:^{}];
	[nc release];
	[vc release];
	
	NSDictionary *metricsInfo = [[NSDictionary alloc] initWithObjectsAndKeys:currentSurvey.identifier, ATSurveyMetricsSurveyIDKey, [NSNumber numberWithInt:ATSurveyWindowTypeSurvey], ATSurveyWindowTypeKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATSurveyDidShowWindowNotification object:nil userInfo:metricsInfo];
	[metricsInfo release], metricsInfo = nil;
}

- (void)presentSurveyControllerWithNoTagsFromViewController:(UIViewController *)viewController {
	if (currentSurvey != nil) {
		[self resetSurvey];
	}
	currentSurvey = [[self surveyWithNoTags] retain];
	if (currentSurvey) {
		[self presentSurveyControllerFromViewControllerWithCurrentSurvey:viewController];
	} else {
		ATLogInfo(@"No surveys without tags found!");
		ATLogInfo(@"Apptentive surveys have a 24 hour caching period. If you've recently created a survey, please reset your device/simulator and try again.");
	}
}

- (void)presentSurveyControllerWithTags:(NSSet *)tags fromViewController:(UIViewController *)viewController {
	if (currentSurvey != nil) {
		[self resetSurvey];
	}
	currentSurvey = [[self surveyWithTags:tags] retain];
	
	if (currentSurvey) {
		[self presentSurveyControllerFromViewControllerWithCurrentSurvey:viewController];
	} else {
		NSString *tagsString = [[[tags allObjects] valueForKey:@"description"] componentsJoinedByString:@", "];
		ATLogInfo(@"No surveys with tags [%@] found!", tagsString);
		ATLogInfo(@"Apptentive surveys have a 24 hour caching period. If you've recently created a survey, please reset your device/simulator and try again.");
	}
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

- (ATSurvey *)surveyWithNoTags {
	ATSurvey *result = nil;
	@synchronized(self) {
		for (ATSurvey *survey in availableSurveys) {
			if ([survey surveyHasNoTags]) {
				if ([survey isEligibleToBeShown]) {
					result = survey;
				}
			}
		}
	}
	return result;
}

- (ATSurvey *)surveyWithTags:(NSSet *)tags {
	ATSurvey *result = nil;
	@synchronized(self) {
		for (ATSurvey *survey in availableSurveys) {
			if ([survey surveyHasTags:tags]) {
				if ([survey isEligibleToBeShown]) {
					result = survey;
				}
			}
		}
	}
	return result;
}

- (BOOL)hasSurveyAvailableWithNoTags {
	ATSurvey *survey = [self surveyWithNoTags];
	if (!survey) {
		ATLogInfo(@"No surveys without tags found!");
		ATLogInfo(@"Apptentive surveys have a 24 hour caching period. If you've recently created a survey, please reset your device/simulator and try again.");
	}
	
	return (survey != nil);
}

- (BOOL)hasSurveyAvailableWithTags:(NSSet *)tags {
	ATSurvey *survey = [self surveyWithTags:tags];
	if (!survey) {
		NSString *tagsString = [[[tags allObjects] valueForKey:@"description"] componentsJoinedByString:@", "];
		ATLogInfo(@"No surveys with tags [%@] found!", tagsString);
		ATLogInfo(@"Apptentive surveys have a 24 hour caching period. If you've recently created a survey, please reset your device/simulator and try again.");
	}
		
	return (survey != nil);
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

@end
