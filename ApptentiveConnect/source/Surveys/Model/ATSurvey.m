//
//  ATSurvey.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurvey.h"

#define kATSurveyStorageVersion 1

@implementation ATSurvey
@synthesize responseRequired;
@synthesize multipleResponsesAllowed;
@synthesize active;
@synthesize date, startTime, endTime;
@synthesize showOncePer;
@synthesize identifier;
@synthesize name;
@synthesize surveyDescription;
@synthesize questions;
@synthesize tags;
@synthesize successMessage;

NSString *const ATSurveyDateShownLastKeyForSurveyID = @"ATSurveyDateShownLastKeyForSurveyID";

- (id)init {
	if ((self = [super init])) {
		questions = [[NSMutableArray alloc] init];
		tags = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		questions = [[NSMutableArray alloc] init];
		tags = [[NSMutableArray alloc] init];
		if (version == kATSurveyStorageVersion) {
			self.active = [coder decodeBoolForKey:@"active"];
			self.date = [coder decodeObjectForKey:@"date"];
			self.startTime = [coder decodeObjectForKey:@"startTime"];
			self.endTime = [coder decodeObjectForKey:@"endTime"];
			self.showOncePer = [coder decodeObjectForKey:@"showOncePer"];
			self.responseRequired = [coder decodeBoolForKey:@"responseRequired"];
			self.multipleResponsesAllowed = [coder decodeBoolForKey:@"multipleResponsesAllowed"];
			self.identifier = [coder decodeObjectForKey:@"identifier"];
			self.name = [coder decodeObjectForKey:@"name"];
			self.surveyDescription = [coder decodeObjectForKey:@"surveyDescription"];
			NSArray *decodedQuestions = [coder decodeObjectForKey:@"questions"];
			if (decodedQuestions) {
				[questions addObjectsFromArray:decodedQuestions];
			}
			NSArray *decodedTags = [coder decodeObjectForKey:@"tags"];
			if (decodedTags) {
				[tags addObjectsFromArray:decodedTags];
			}
			self.successMessage = [coder decodeObjectForKey:@"successMessage"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATSurveyStorageVersion forKey:@"version"];
	[coder encodeObject:self.identifier forKey:@"identifier"];
	[coder encodeBool:self.isActive forKey:@"active"];
	[coder encodeObject:self.date forKey:@"date"];
	[coder encodeObject:self.startTime forKey:@"startTime"];
	[coder encodeObject:self.endTime forKey:@"endTime"];
	[coder encodeObject:self.showOncePer forKey:@"showOncePer"];
	[coder encodeBool:self.responseIsRequired forKey:@"responseRequired"];
	[coder encodeBool:self.multipleResponsesAllowed forKey:@"multipleResponsesAllowed"];
	[coder encodeObject:self.name forKey:@"name"];
	[coder encodeObject:self.surveyDescription forKey:@"surveyDescription"];
	[coder encodeObject:self.questions forKey:@"questions"];
	[coder encodeObject:self.tags forKey:@"tags"];
	[coder encodeObject:self.successMessage forKey:@"successMessage"];
}

- (void)dealloc {
	[questions release], questions = nil;
	[identifier release], identifier = nil;
	[name release], name = nil;
	[surveyDescription release], surveyDescription = nil;
	[successMessage release], successMessage = nil;
	[tags release], tags = nil;
	[date release], date = nil;
	[startTime release], startTime = nil;
	[endTime release], endTime = nil;	
	[showOncePer release], showOncePer = nil;
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<ATSurvey: %p {name:%@, identifier:%@}>", self, self.name, self.identifier];
}

- (void)addQuestion:(ATSurveyQuestion *)question {
	[questions addObject:question];
}

- (void)addTag:(NSString *)tag {
	if (tag && [tag length]) {
		[tags addObject:[tag lowercaseString]];
	}
}

- (BOOL)surveyHasNoTags {
	if (self.tags == nil || [self.tags count] == 0) {
		return YES;
	}
	return NO;
}

- (BOOL)surveyHasTags:(NSSet *)tagsToCheck {
	if (tagsToCheck == nil || [tagsToCheck count] == 0) {
		return YES;
	}
	
	// We want to make sure that all of the tags to check are present.
	if (self.tags == nil || [self.tags count] == 0) {
		return NO;
	}
	
	NSSet *tagSet = [NSSet setWithArray:self.tags];
	BOOL isSubset = YES;
	for (NSString *tag in tagsToCheck) {
		// We want to check lower case tags, so don't just use NSSet methods.
		NSString *lowercaseTag = [tag lowercaseString];
		if (![tagSet containsObject:lowercaseTag]) {
			isSubset = NO;
			break;
		}
	}
	
	return isSubset;
}

- (BOOL)isStarted {
	if (self.startTime == nil) {
		return YES;
	}
	
	return ([self.startTime compare:[NSDate date]] == NSOrderedAscending);
}

- (BOOL)isEnded {
	if (self.endTime == nil) {
		return NO;
	}
	
	return ([self.endTime compare:[NSDate date]] == NSOrderedAscending);
}

- (BOOL)shownTooRecently {
	NSDate *shownLast = nil;
	@synchronized([ATSurvey class]) {
		NSDictionary *shownDates = [[NSUserDefaults standardUserDefaults] objectForKey:ATSurveyDateShownLastKeyForSurveyID];
		if (shownDates && [shownDates objectForKey:self.identifier]) {
			shownLast = (NSDate *)[shownDates objectForKey:self.identifier];
		}
	}
	
	if (self.showOncePer == nil || shownLast == nil) {
		return NO;
	}
		
	NSDate *showAgain = [shownLast dateByAddingTimeInterval:60 * [self.showOncePer doubleValue]];
	return ([showAgain compare:[NSDate date]] == NSOrderedDescending);
}

- (void)setShownAtDate:(NSDate *)shownDate {
	@synchronized([ATSurvey class]) {
		NSDictionary *shownDates = [[NSUserDefaults standardUserDefaults] objectForKey:ATSurveyDateShownLastKeyForSurveyID];
		if (!shownDates) {
			shownDates = @{};
		}
		NSMutableDictionary *shownDatesMutable = [NSMutableDictionary dictionaryWithDictionary:shownDates];
		if (shownDate == nil) {
			[shownDatesMutable removeObjectForKey:self.identifier];
		} else {
			[shownDatesMutable setObject:shownDate forKey:self.identifier];
		}
		[[NSUserDefaults standardUserDefaults] setObject:shownDatesMutable forKey:ATSurveyDateShownLastKeyForSurveyID];
		if (![[NSUserDefaults standardUserDefaults] synchronize]) {
			ATLogError(@"Unable to synchronize defaults for survey shown at dates.");
		}
	}
}

- (void)reset {
	for (ATSurveyQuestion *question in questions) {
		[question reset];
	}
}
@end
