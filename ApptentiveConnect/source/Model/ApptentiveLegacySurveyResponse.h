//
//  ApptentiveLegacySurveyResponse.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

@interface ApptentiveLegacySurveyResponse : ApptentiveRecord

@property (copy, nonatomic) NSString *pendingSurveyResponseID;
@property (copy, nonatomic) NSData *answersData;
@property (copy, nonatomic) NSString *surveyID;
@property (strong, nonatomic) NSNumber *pendingState;

+ (void)enqueueUnsentSurveyResponsesInContext:(NSManagedObjectContext *)context;

@end
