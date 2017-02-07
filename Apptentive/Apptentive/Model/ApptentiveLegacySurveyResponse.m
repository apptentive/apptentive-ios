//
//  ApptentiveLegacySurveyResponse.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/9/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveLegacySurveyResponse.h"
#import "ApptentiveSerialRequest+Record.h"


@implementation ApptentiveLegacySurveyResponse

@dynamic pendingSurveyResponseID;
@dynamic answersData;
@dynamic surveyID;
@dynamic pendingState;

+ (void)enqueueUnsentSurveyResponsesInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ATSurveyResponse"];

	NSError *error;
	NSArray *unsentSurveyResponses = [context executeFetchRequest:request error:&error];

	if (unsentSurveyResponses == nil) {
		ApptentiveLogError(@"Unable to retrieve unsent events: %@", error);
		return;
	}

	for (ApptentiveLegacySurveyResponse *response in unsentSurveyResponses) {
		[ApptentiveSerialRequest enqueueRequestWithPath:[NSString stringWithFormat:@"surveys/%@/respond", response.surveyID] method:@"POST" payload:response.apiJSON attachments:nil identifier:nil inContext:context];
		[context deleteObject:response];
	}
}

- (NSDictionary *)apiJSON {
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
