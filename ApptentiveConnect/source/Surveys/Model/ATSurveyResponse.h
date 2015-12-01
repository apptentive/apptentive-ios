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
@property (strong, nonatomic) NSString *pendingSurveyResponseID;
@property (strong, nonatomic) NSData *answersData;
@property (strong, nonatomic) NSString *surveyID;
@property (strong, nonatomic) NSNumber *pendingState;

- (void)setAnswers:(NSDictionary *)answers;
+ (ATSurveyResponse *)findSurveyResponseWithPendingID:(NSString *)pendingID;
@end
