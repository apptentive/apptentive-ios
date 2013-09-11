//
//  ApptentiveSurveysTests.m
//  ApptentiveSurveysTests
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveSurveysTests.h"
#import "ATSurvey.h"
#import "ATSurveysBackend.h"
#import "ATSurveyParser.h"
#import "ATSurveyQuestion.h"

@implementation ApptentiveSurveysTests

- (void)setUp
{
	[super setUp];
	
	// Set-up code here.
}

- (void)tearDown
{
	// Tear-down code here.
	[super tearDown];
}

- (void)testSurveyParsing {
	NSString *surveyString = @"{\"surveys\":[{\"id\":\"4eb4877cd4d8f8000100002a\",\"questions\":[{\"id\":\"4eb4877cd4d8f8000100002b\",\"answer_choices\":[{\"id\":\"4eb4877cd4d8f8000100002c\",\"value\":\"BMW 335i\"},{\"id\":\"4eb4877cd4d8f8000100002d\",\"value\":\"BMW 335i\"},{\"id\":\"4eb4877cd4d8f8000100002e\",\"value\":\"Bugatti Veyron\"},{\"id\":\"4eb4877cd4d8f8000100002f\",\"value\":\"Tesla Model S\"},{\"id\":\"4eb4877cd4d8f80001000030\",\"value\":\"Dodge Charger\"},{\"id\":\"4eb4877cd4d8f80001000031\",\"value\":\"Other\"}],\"value\":\"Which car would you rather drive?\",\"type\":\"multichoice\"},{\"id\":\"4eb4877cd4d8f80001000032\",\"value\":\"If Other, Please Elaborate:\",\"type\":\"singleline\"},{\"id\":\"4eb4877cd4d8f80001000033\",\"value\":\"How does a really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really long question appear?\",\"type\":\"singleline\"}],\"responses\":[{\"question\":\"Which car would you rather drive?\",\"type\":\"multichoice\",\"responses\":{}},{\"question\":\"If Other, Please Elaborate:\",\"type\":\"singleline\",\"responses\":[]},{\"question\":\"How does a really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really, really long question appear?\",\"type\":\"singleline\",\"responses\":[]}],\"name\":\"Happy Fun Test Survey\",\"description\":\"This is a fun test survey with a description like this.\",\"active\":true}]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	STAssertNotNil(surveyData, @"Survey data shouldn't be nil");
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	
	STAssertTrue([surveys count] == 1, @"Should only be 1 survey");
	
	ATSurvey *survey = [surveys objectAtIndex:0];
	STAssertTrue([survey.identifier isEqualToString:@"4eb4877cd4d8f8000100002a"], @"id mismatch");
	STAssertTrue([survey.name isEqualToString:@"Happy Fun Test Survey"], @"name mismatch");
	STAssertTrue([survey.surveyDescription isEqualToString:@"This is a fun test survey with a description like this."], @"description mismatch");
	STAssertTrue(survey.isActive, @"Survey should be active");
	STAssertTrue([[survey questions] count] == 3 , @"Should be 3 questions");
	STAssertTrue([survey surveyHasNoTags], @"Survey shouldn't have any tags.");
	
	[survey addTag:@"video"];
	[survey addTag:@"played"];
	NSSet *goodSet = [NSSet setWithObjects:@"video", @"played", nil];
	NSSet *badSet = [NSSet setWithObjects:@"video", @"paused", nil];
	STAssertTrue([survey surveyHasTags:goodSet], @"Survey should have some tags.");
	STAssertFalse([survey surveyHasTags:badSet], @"Survey should not have these tags.");
	
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
	STAssertTrue([question.answerChoices count] == 6, @"First question should have 6 answers");
	
	[parser release], parser = nil;
}

- (void)testSingleLineParsing {
	NSString *surveyString = @"{\"surveys\":[{\"id\":\"51bbd4eb4712c7a70d000001\",\"questions\":[{\"id\":\"51bbd4eb4712c7a70d000002\",\"value\":\"Test\",\"type\":\"singleline\",\"required\":false}],\"date\":\"2013-06-15T02:43:55Z\",\"name\":\"Test\",\"description\":\"Test\",\"required\":false,\"multiple_responses\":false,\"show_success_message\":false,\"active\":true},{\"id\":\"51d494cc4712c7012c000059\",\"questions\":[{\"id\":\"51d494cc4712c7012c00005a\",\"multiline\":false,\"value\":\"Single line response type\",\"type\":\"singleline\",\"required\":true},{\"id\":\"51d494cc4712c7012c00005b\",\"multiline\":true,\"value\":\"Multiline response type\",\"type\":\"singleline\",\"required\":true}],\"date\":\"2013-07-03T21:17:00Z\",\"name\":\"Test New Surveys\",\"required\":false,\"multiple_responses\":false,\"show_success_message\":false,\"start_time\":\"2013-07-03T21:15:55Z\",\"active\":true}]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	STAssertNotNil(surveyData, @"Survey data shouldn't be nil");
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	
	STAssertTrue([surveys count] == 2, @"Should be 2 surveys");
	
	ATSurvey *survey = [surveys objectAtIndex:0];
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
	STAssertTrue(question.multiline, @"Questions without multiline attribute should be multiple lines by default.");
	
	
	survey = [surveys objectAtIndex:1];
	question = [[survey questions] objectAtIndex:0];
	STAssertFalse(question.multiline, @"Question should be a single line.");
	
	question = [[survey questions] objectAtIndex:1];
	STAssertTrue(question.multiline, @"Question should be multiple lines.");
	
	[parser release], parser = nil;
}

- (void)testEmptySurvey {
	NSString *surveyString = @"{\"surveys\":[]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	STAssertNotNil(surveyData, @"Survey data shouldn't be nil");

	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	STAssertNotNil(surveys, @"shouldn't be nil");
	STAssertTrue([surveys count] == 0, @"Should be zero surveys");
}

- (void)testMultipleSelectValidation {
	ATSurveyQuestion *question = [[ATSurveyQuestion alloc] init];
	question.type = ATSurveyQuestionTypeMultipleSelect;
	question.value = @"Pick one:";
	
	ATSurveyQuestionAnswer *answerA = [[ATSurveyQuestionAnswer alloc] init];
	answerA.identifier = @"a";
	answerA.value = @"A";
	
	ATSurveyQuestionAnswer *answerB = [[ATSurveyQuestionAnswer alloc] init];
	answerB.identifier = @"b";
	answerB.value = @"B";
	
	[question addAnswerChoice:answerA];
	[question addAnswerChoice:answerB];
	question.minSelectionCount = 1;
	question.maxSelectionCount = 1;
	question.responseRequired = YES;
	
	STAssertEquals(ATSurveyQuestionValidationErrorTooFewAnswers, [question validateAnswer], @"Should be too few answers");
	[question addSelectedAnswerChoice:answerA];
	STAssertEquals(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
	question.minSelectionCount = 2;
	question.maxSelectionCount = 2;
	STAssertEquals(ATSurveyQuestionValidationErrorTooFewAnswers, [question validateAnswer], @"Should be too few answers");
	question.minSelectionCount = 1;
	question.maxSelectionCount = 1;
	[question addSelectedAnswerChoice:answerB];
	STAssertEquals(ATSurveyQuestionValidationErrorTooManyAnswers, [question validateAnswer], @"Should be too many answers");
	question.responseRequired = NO;
	STAssertEquals(ATSurveyQuestionValidationErrorTooManyAnswers, [question validateAnswer], @"Should be too many answers");
	[question removeSelectedAnswerChoice:answerB];
	STAssertEquals(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
	[question removeSelectedAnswerChoice:answerA];
	STAssertEquals(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
}

- (void)testStartAndEndDates {
	ATSurvey *survey = [[ATSurvey alloc] init];
	
	survey.startTime = nil;
	STAssertTrue([survey isStarted], @"nil start dates should mean the survey is valid to start.");
	
	survey.startTime = [NSDate dateWithTimeIntervalSinceNow:100];
	STAssertFalse([survey isStarted], @"Surveys with start times in the future should not have started.");
	
	survey.startTime = [NSDate dateWithTimeIntervalSinceNow:-100];
	STAssertTrue([survey isStarted], @"Surveys with start times in the past should have started.");
	
	survey.endTime = nil;
	STAssertFalse([survey isEnded], @"nil end dates should mean the survey hasn't ended yet.");
	
	survey.endTime = [NSDate dateWithTimeIntervalSinceNow:100];
	STAssertFalse([survey isEnded], @"Surveys with end times in the future should not have ended.");
	
	survey.endTime = [NSDate dateWithTimeIntervalSinceNow:-99];
	STAssertTrue([survey isEnded], @"Surveys with end times in the past should have ended.");
}

- (void)testSurveyViewLimits {
	ATSurvey *survey = [[ATSurvey alloc] init];
	survey.identifier = @"1234567890";
	
	[survey removeAllViewDates];
	NSArray *viewDates = [survey viewDates];
	STAssertNotNil(viewDates, @"View dates shouldn't be nil");
	STAssertTrue([viewDates count] == 0, @"Should remove all view dates.");
	
	survey.viewCount = @(0);
	survey.viewPeriod = @(100);
	[survey removeAllViewDates];
	[survey addViewDate:[NSDate date]];
	STAssertTrue([survey isWithinViewLimits], @"Surveys with viewCount == 0 should always be within view limits");
	
	survey.viewCount = nil;
	STAssertTrue([survey isWithinViewLimits], @"Surveys with nil viewCount should be within view limits");

	survey.viewCount = @(10);
	survey.viewPeriod = nil;
	STAssertTrue([survey isWithinViewLimits], @"Surveys with nil viewPeriod should be within view limits");

	survey.viewCount = @(3);
	survey.viewPeriod = @(1000);
	
	[survey removeAllViewDates];
	STAssertTrue([survey isWithinViewLimits], @"Surveys with nil viewDates should be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-50 sinceDate:[NSDate date]]];
	[survey addViewDate:[NSDate dateWithTimeInterval:-40 sinceDate:[NSDate date]]];
	STAssertTrue([survey isWithinViewLimits], @"Surveys with viewDates less than viewCount should always be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-30 sinceDate:[NSDate date]]];
	STAssertFalse([survey isWithinViewLimits], @"Surveys with viewDates == viewCount (within period) should NOT be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-20 sinceDate:[NSDate date]]];
	STAssertFalse([survey isWithinViewLimits], @"Surveys with viewDates > viewCount (within period) should NOT be within view limits");
	
	survey.viewCount = @(2);
	survey.viewPeriod = @(1000);
	[survey removeAllViewDates];
	[survey addViewDate:[NSDate dateWithTimeInterval:-4000 sinceDate:[NSDate date]]];
	[survey addViewDate:[NSDate dateWithTimeInterval:-3000 sinceDate:[NSDate date]]];
	[survey addViewDate:[NSDate dateWithTimeInterval:-2000 sinceDate:[NSDate date]]];
	STAssertTrue([survey isWithinViewLimits], @"Surveys with many viewDates outside the viewPeriod, but 0 in the viewPeriod, should be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-50 sinceDate:[NSDate date]]];
	STAssertTrue([survey isWithinViewLimits], @"Surveys with many viewDates outside the viewPeriod, but viewDates < viewCount in the viewPeriod, should be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-40 sinceDate:[NSDate date]]];
	STAssertFalse([survey isWithinViewLimits], @"Surveys with many viewDates outside the viewPeriod, but viewDates == viewCount in the viewPeriod, should not be within view limits");
	[survey addViewDate:[NSDate dateWithTimeInterval:-30 sinceDate:[NSDate date]]];
	STAssertFalse([survey isWithinViewLimits], @"Surveys with many viewDates outside the viewPeriod, but viewDates > viewCount in the viewPeriod, should not be within view limits");
	
	survey.viewCount = @(2);
	survey.viewPeriod = @(3);
	[survey removeAllViewDates];
	[survey addViewDate:[NSDate date]];
	[survey addViewDate:[NSDate date]];
	STAssertFalse([survey isWithinViewLimits], @"View count was exceeded in the period, should not be within view limits.");
	[NSThread sleepForTimeInterval:3.0f];
	STAssertTrue([survey isWithinViewLimits], @"View times have lapsed out of period, should now be within view limits.");
}

- (void)testSurveyEligibilityToBeShown {
	ATSurvey *survey = [[ATSurvey alloc] init];
	survey.identifier = @"1234567890";
	
	survey.active = YES;
	survey.startTime = [NSDate dateWithTimeIntervalSinceNow:-100];
	survey.endTime = [NSDate dateWithTimeIntervalSinceNow:100];
	survey.viewCount = @(2);
	survey.viewPeriod = @(100);
	[survey removeAllViewDates];
	survey.multipleResponsesAllowed = YES;
	
	STAssertTrue([survey isEligibleToBeShown], @"Eligible to be shown:active, start time in past, end time in future, within view limits.");
	survey.active = NO;
	STAssertFalse([survey isEligibleToBeShown], @"Not Eligible to be shown: not active");
	survey.active = YES;
	survey.startTime = [NSDate dateWithTimeIntervalSinceNow:20];
	STAssertFalse([survey isEligibleToBeShown], @"Not Eligible to be shown: start time in future.");
	survey.startTime = [NSDate dateWithTimeIntervalSinceNow:-100];
	survey.endTime = [NSDate dateWithTimeIntervalSinceNow:-20];
	STAssertFalse([survey isEligibleToBeShown], @"Not Eligible to be shown: end time in past.");
	survey.endTime = [NSDate dateWithTimeIntervalSinceNow:100];
	[survey addViewDate:[NSDate date]];
	[survey addViewDate:[NSDate date]];
	STAssertFalse([survey isEligibleToBeShown], @"Not Eligible to be shown: hit view limits for period");
	[survey removeAllViewDates];
	STAssertTrue([survey isEligibleToBeShown], @"Eligible to be shown:active, start time in past, end time in future, within view limits.");
	
	[[ATSurveysBackend sharedBackend] setDidSendSurvey:survey];
	survey.multipleResponsesAllowed = NO;
	STAssertFalse([survey isEligibleToBeShown], @"Not Eligible to be shown: Survey was already sent, multiple responses not allowed.");
	survey.multipleResponsesAllowed = YES;
	STAssertTrue([survey isEligibleToBeShown], @"Eligible to be shown: Survey was already sent, but multiple responses are allowed.");
}
@end
