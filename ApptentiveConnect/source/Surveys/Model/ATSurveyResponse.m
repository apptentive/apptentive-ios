//
//  ATSurveyResponse.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 7/8/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATSurveyResponse.h"
#import "ATData.h"


@implementation ATSurveyResponse
@dynamic pendingSurveyResponseID;
@dynamic answersData;
@dynamic surveyID;
@dynamic pendingState;

+ (NSObject *)newInstanceWithJSON:(NSDictionary *)json {
	NSAssert(NO, @"Abstract method called.");
	return nil;
}

+ (ATSurveyResponse *)findSurveyResponseWithPendingID:(NSString *)pendingID {
	ATSurveyResponse *result = nil;
	
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingSurveyResponseID == %@)", pendingID];
		NSArray *results = [ATData findEntityNamed:@"ATSurveyResponse" withPredicate:fetchPredicate];
		if (results && [results count] != 0) {
			result = [results objectAtIndex:0];
		}
	}
	return result;
}

- (void)setup {
	[super setup];
	if (self.pendingSurveyResponseID == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
		CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
		
		self.pendingSurveyResponseID = [NSString stringWithFormat:@"pending-survey-response:%@", (NSString *)uuidStringRef];
		
		CFRelease(uuidRef), uuidRef = NULL;
		CFRelease(uuidStringRef), uuidStringRef = NULL;
	}
}

- (void)awakeFromInsert {
	[super awakeFromInsert];
	[self setup];
}

- (void)updateWithJSON:(NSDictionary *)json {
	[super updateWithJSON:json];
}

- (NSDictionary *)apiJSON {
	NSDictionary *superJSON = [super apiJSON];
	NSMutableDictionary *survey = [NSMutableDictionary dictionary];
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
	
	NSDictionary *result = @{@"survey":survey};
	return result;
}

- (void)setAnswers:(NSDictionary *)answers {
	self.answersData = [self dataForAnswersDictionary:answers];
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
			ATLogError(@"Unable to unarchive answers data: %@", exception);
		}
		return result;
	}
}

- (NSData *)dataForAnswersDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) {
		return nil;
	} else {
		return [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	}
}
@end
