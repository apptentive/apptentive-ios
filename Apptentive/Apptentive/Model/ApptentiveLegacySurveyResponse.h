//
//  ApptentiveLegacySurveyResponse.h
//  Apptentive
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecord.h"

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveConversation;


/**
 Used to represent legacy survey responses waiting to be sent in Core Data.
 */
@interface ApptentiveLegacySurveyResponse : ApptentiveRecord

@property (copy, nonatomic) NSString *pendingSurveyResponseID;
@property (copy, nonatomic) NSData *answersData;
@property (copy, nonatomic) NSString *surveyID;
@property (strong, nonatomic) NSNumber *pendingState;

/**
 Migrates legacy survey responses waiting to be sent in Core Data into
 `ApptentiveSerialRequest` objects.

 @param context The managed object context to use to migrate survey responses.
 */
+ (void)enqueueUnsentSurveyResponsesInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
