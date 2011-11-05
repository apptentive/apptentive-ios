//
//  ATSurveys.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveys.h"
#import "ATSurveysBackend.h"

@interface ATSurveys ()
+ (ATSurveys *)sharedSurveys;
@end

@implementation ATSurveys
+ (ATSurveys *)sharedSurveys {
	static ATSurveys *sharedSingleton = nil;
	@synchronized(self) {
		if (sharedSingleton == nil) {
			sharedSingleton = [[ATSurveys alloc] init];
		}
	}
	return sharedSingleton;
}

+ (void)checkForAvailableSurveys {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend checkForAvailableSurveys];
}

@end
