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
		
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
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
		
	}
	return result;
}

- (ATSurvey *)surveyWithTags:(NSSet *)tags {
	ATSurvey *result = nil;
	@synchronized(self) {
		
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
