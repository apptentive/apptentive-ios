//
//  ATSurveyResponse.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ATJSONModel.h"
#import "ATRecord.h"

typedef enum {
	ATPendingSurveyResponseStateSending,
	ATPendingSurveyResponseConfirmed,
	ATPendingSurveyResponseError
} ATPendingSurveyResponseState;

@interface ATSurveyResponse : ATRecord <ATJSONModel>
@property (nonatomic, retain) NSString *pendingSurveyResponseID;
@property (nonatomic, retain) NSData *answersData;
@property (nonatomic, retain) NSString *surveyID;
@property (nonatomic, retain) NSNumber *pendingState;

- (void)setAnswers:(NSDictionary *)answers;
+ (ATSurveyResponse *)findSurveyResponseWithPendingID:(NSString *)pendingID;
@end
