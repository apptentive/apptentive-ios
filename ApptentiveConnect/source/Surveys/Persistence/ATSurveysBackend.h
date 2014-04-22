//
//  ATSurveysBackend.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ATSurvey;

extern NSString *const ATSurveyNewSurveyAvailableNotification;
extern NSString *const ATSurveySentNotification;

extern NSString *const ATSurveyIDKey;

@interface ATSurveysBackend : NSObject {
	
}
+ (ATSurveysBackend *)sharedBackend;
- (void)setDidSendSurvey:(ATSurvey *)survey;
@end

@interface ATSurveysBackend (Private)
- (BOOL)surveyAlreadySubmitted:(ATSurvey *)survey;
@end
