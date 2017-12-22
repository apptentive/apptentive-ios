//
//  ApptentiveLegacySurveyResponse.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacySurveyResponse.h"
#import "ApptentiveBackend.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveSurveyResponsePayload.h"
#import "Apptentive_Private.h"

NS_ASSUME_NONNULL_BEGIN


@implementation ApptentiveLegacySurveyResponse

@dynamic pendingSurveyResponseID;
@dynamic answersData;
@dynamic surveyID;
@dynamic pendingState;

+ (void)enqueueUnsentSurveyResponsesInContext:(NSManagedObjectContext *)context forConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(context, @"Context is nil");
	ApptentiveAssertNotNil(conversation, @"Conversation is nil");

	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATSurveyResponse"];

	NSError *error;
	NSArray *unsentSurveyResponses = [context executeFetchRequest:request error:&error];

	if (unsentSurveyResponses == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent events: %@", error);
		return;
	}

	for (ApptentiveLegacySurveyResponse *response in unsentSurveyResponses) {
		NSDictionary *JSON = response.apiJSON[@"survey"];

		NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:[JSON[@"client_created_at"] doubleValue]];
		ApptentiveSurveyResponsePayload *payload = [[ApptentiveSurveyResponsePayload alloc] initWithAnswers:JSON[@"answers"] identifier:JSON[@"id"] creationDate:creationDate];
		ApptentiveAssertNotNil(payload, @"Failed to create a survey response payload");

		if (payload != nil) {
			[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:context];
		}

		[context deleteObject:response];
	}
}

- (nullable NSDictionary *)apiJSON {
	NSDictionary *superJSON = [super apiJSON];
	NSMutableDictionary *survey = [NSMutableDictionary dictionary];
	survey[@"id"] = self.surveyID;
	if (self.pendingSurveyResponseID != nil) {
		survey[@"nonce"] = self.pendingSurveyResponseID;
	}
	NSDictionary *answers = [self dictionaryForAnswers];
	if (answers) {
		survey[@"answers"] = answers;
	}
	if ([superJSON objectForKey:@"client_created_at"]) {
		survey[@"client_created_at"] = superJSON[@"client_created_at"];
	}
	if ([superJSON objectForKey:@"client_created_at_utc_offset"]) {
		survey[@"client_created_at_utc_offset"] = superJSON[@"client_created_at_utc_offset"];
	}

	NSDictionary *result = @{ @"survey": survey };
	return result;
}

#pragma mark Private

- (NSDictionary *)dictionaryForAnswers {
	if (self.answersData == nil) {
		return @{};
	} else {
		NSDictionary *result = nil;
		@try {
			result = [NSKeyedUnarchiver unarchiveObjectWithData:self.answersData];
		} @catch (NSException *exception) {
			ApptentiveLogError(@"Unable to unarchive answers data: %@", exception);
		}
		return result;
	}
}

@end

NS_ASSUME_NONNULL_END
