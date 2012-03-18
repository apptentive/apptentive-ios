//
//  ATSurveyTask.h
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATTask.h"
#import "ATAPIRequest.h"

@class ATSurveyResponse;

@interface ATSurveyTask : ATTask <ATAPIRequestDelegate> {
@private
	ATAPIRequest *request;
	ATSurveyResponse *surveyResponse$;
}
@property (nonatomic, retain) ATSurveyResponse *surveyResponse;

@end
