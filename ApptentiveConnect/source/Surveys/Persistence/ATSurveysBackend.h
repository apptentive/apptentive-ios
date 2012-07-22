//
//  ATSurveysBackend.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSurvey;

@interface ATSurveysBackend : NSObject {
@private
	ATSurvey *currentSurvey;
}
+ (ATSurveysBackend *)sharedBackend;
- (void)checkForAvailableSurveys;
- (ATSurvey *)currentSurvey;
- (void)resetSurvey;
- (void)presentSurveyControllerFromViewController:(UIViewController *)viewController;
- (void)setDidSendSurvey:(ATSurvey *)survey;
@end


@interface ATSurveysBackend (Private)
- (BOOL)surveyAlreadySubmitted:(ATSurvey *)survey;
- (void)didReceiveNewSurvey:(ATSurvey *)survey;
@end