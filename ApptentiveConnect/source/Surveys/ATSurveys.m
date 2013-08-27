//
//  ATSurveys.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurveys.h"
#import "ATSurveysBackend.h"

NSString *const ATSurveyNewSurveyAvailableNotification = @"ATSurveyNewSurveyAvailableNotification";
NSString *const ATSurveySentNotification = @"ATSurveySentNotification";

NSString *const ATSurveyIDKey = @"ATSurveyIDKey";

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

+ (BOOL)hasSurveyAvailable {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	return [backend currentSurvey] != nil;
}

+ (void)checkForAvailableSurveys {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend checkForAvailableSurveys];
}


+ (void)presentSurveyControllerFromViewController:(UIViewController *)viewController {
	ATSurveysBackend *backend = [ATSurveysBackend sharedBackend];
	[backend presentSurveyControllerFromViewController:viewController];
}
@end
