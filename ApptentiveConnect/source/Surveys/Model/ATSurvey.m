//
//  ATSurvey.m
//  ApptentiveSurveys
//
//  Created by Andrew Wooster on 11/5/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ATSurvey.h"
#import "ATSurveysBackend.h"

#define kATSurveyStorageVersion 1

@implementation ATSurvey
@synthesize responseRequired;
@synthesize multipleResponsesAllowed;
@synthesize active;
@synthesize date, startTime, endTime;
@synthesize viewCount, viewPeriod;
@synthesize identifier;
@synthesize name;
@synthesize surveyDescription;
@synthesize questions;
@synthesize tags;
@synthesize successMessage;

NSString *const ATSurveyViewDatesKey = @"ATSurveyViewDatesKey";

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
			self.viewCount = [coder decodeObjectForKey:@"viewCount"];
			self.viewPeriod = [coder decodeObjectForKey:@"viewPeriod"];
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
	[coder encodeObject:self.viewCount forKey:@"viewCount"];
	[coder encodeObject:self.viewPeriod forKey:@"viewPeriod"];
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
	[viewCount release], viewCount = nil;
	[viewPeriod release], viewPeriod = nil;
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

- (BOOL)isEligibleToBeShown {
	BOOL eligible = ([self isActive] && [self isStarted] && ![self isEnded] && [self isWithinViewLimits]);
	
	BOOL responseAllowed = (![self wasAlreadySubmitted] || [self multipleResponsesAllowed]);
	
	return (eligible && responseAllowed);
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

- (BOOL)wasAlreadySubmitted {
	return [[ATSurveysBackend sharedBackend] surveyAlreadySubmitted:self];
}

- (NSArray *)viewDates {
	NSArray *viewDates = nil;
	@synchronized([ATSurvey class]) {
		NSDictionary *surveysViewDates = [[NSUserDefaults standardUserDefaults] objectForKey:ATSurveyViewDatesKey];
		viewDates = [surveysViewDates objectForKey:self.identifier];
	}
	if (!viewDates) {
		viewDates = @[];
	}
	return viewDates;
}

- (void)addViewDate:(NSDate *)viewDate {
	NSAssert(viewDate != nil, @"Shouldn't be passing in nil values to add methods");
	NSMutableArray *viewDates = [NSMutableArray arrayWithArray:[self viewDates]];
	if (viewDate != nil) {
		[viewDates insertObject:viewDate atIndex:0];
	}
		
	@synchronized([ATSurvey class]) {
		NSMutableDictionary *surveysViewDates = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:ATSurveyViewDatesKey]];
		[surveysViewDates setObject:viewDates forKey:self.identifier];
		
		[[NSUserDefaults standardUserDefaults] setObject:surveysViewDates forKey:ATSurveyViewDatesKey];
		if (![[NSUserDefaults standardUserDefaults] synchronize]) {
			ATLogError(@"Unable to synchronize defaults for survey view dates.");
		}
	}
}

- (void)removeAllViewDates {
	@synchronized([ATSurvey class]) {
		NSMutableDictionary *surveysViewDates = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:ATSurveyViewDatesKey]];
		if (self.identifier) {
			[surveysViewDates removeObjectForKey:self.identifier];
			
			[[NSUserDefaults standardUserDefaults] setObject:surveysViewDates forKey:ATSurveyViewDatesKey];
			if (![[NSUserDefaults standardUserDefaults] synchronize]) {
				ATLogError(@"Unable to synchronize defaults for survey view dates.");
			}
		}
	}
}

- (BOOL)isWithinViewLimits {
	NSArray *viewDates = [self viewDates];
	
	if (self.viewCount == nil || self.viewPeriod == nil || [viewDates count] == 0) {
		return YES;
	}
	
	if ([self.viewCount intValue] == 0 || self.viewDates.count < [self.viewCount intValue]) {
		return YES;
	}
	
	NSDate *cutoff = [[NSDate date] dateByAddingTimeInterval: -[self.viewPeriod doubleValue]];
	
	int viewDatesWithinCutoff = 0;
	for (NSDate *viewDate in viewDates) {
		if ([cutoff compare:viewDate] == NSOrderedAscending) {
			viewDatesWithinCutoff++;
		}
	}
	
	return (viewDatesWithinCutoff < [self.viewCount intValue]);
}

- (void)reset {
	for (ATSurveyQuestion *question in questions) {
		[question reset];
	}
}

@end
