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

@implementation ATSurveysBackend

+ (ATSurveysBackend *)sharedBackend {
	static ATSurveysBackend *sharedBackend = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *defaultPreferences = @{};
		[defaults registerDefaults:defaultPreferences];
		
		sharedBackend = [[ATSurveysBackend alloc] init];
	});
	return sharedBackend;
}

- (id)init {
	if ((self = [super init])) {
		
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

@end
