//
//  ApptentiveSurveysTests.m
//  ApptentiveSurveysTests
//
//  Created by Andrew Wooster on 11/4/11.
//  Copyright (c) 2011 Apptentive. All rights reserved.
//

#import "ApptentiveSurveysTests.h"
#import "ATSurvey.h"
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
	XCTAssertNotNil(surveyData, @"Survey data shouldn't be nil");
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	
	XCTAssertTrue([surveys count] == 1, @"Should only be 1 survey");
	
	ATSurvey *survey = [surveys objectAtIndex:0];
	XCTAssertTrue([survey.identifier isEqualToString:@"4eb4877cd4d8f8000100002a"], @"id mismatch");
	XCTAssertTrue([survey.name isEqualToString:@"Happy Fun Test Survey"], @"name mismatch");
	XCTAssertTrue([survey.surveyDescription isEqualToString:@"This is a fun test survey with a description like this."], @"description mismatch");
	XCTAssertTrue(survey.isActive, @"Survey should be active");
	XCTAssertTrue([[survey questions] count] == 3 , @"Should be 3 questions");
	XCTAssertTrue([survey surveyHasNoTags], @"Survey shouldn't have any tags.");
	
	[survey addTag:@"video"];
	[survey addTag:@"played"];
	NSSet *goodSet = [NSSet setWithObjects:@"video", @"played", nil];
	NSSet *badSet = [NSSet setWithObjects:@"video", @"paused", nil];
	XCTAssertTrue([survey surveyHasTags:goodSet], @"Survey should have some tags.");
	XCTAssertFalse([survey surveyHasTags:badSet], @"Survey should not have these tags.");
	
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
	XCTAssertTrue([question.answerChoices count] == 6, @"First question should have 6 answers");
	
	[parser release], parser = nil;
}

- (void)testSingleLineParsing {
	NSString *surveyString = @"{\"surveys\":[{\"id\":\"51bbd4eb4712c7a70d000001\",\"questions\":[{\"id\":\"51bbd4eb4712c7a70d000002\",\"value\":\"Test\",\"type\":\"singleline\",\"required\":false}],\"date\":\"2013-06-15T02:43:55Z\",\"name\":\"Test\",\"description\":\"Test\",\"required\":false,\"multiple_responses\":false,\"show_success_message\":false,\"active\":true},{\"id\":\"51d494cc4712c7012c000059\",\"questions\":[{\"id\":\"51d494cc4712c7012c00005a\",\"multiline\":false,\"value\":\"Single line response type\",\"type\":\"singleline\",\"required\":true},{\"id\":\"51d494cc4712c7012c00005b\",\"multiline\":true,\"value\":\"Multiline response type\",\"type\":\"singleline\",\"required\":true}],\"date\":\"2013-07-03T21:17:00Z\",\"name\":\"Test New Surveys\",\"required\":false,\"multiple_responses\":false,\"show_success_message\":false,\"start_time\":\"2013-07-03T21:15:55Z\",\"active\":true}]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertNotNil(surveyData, @"Survey data shouldn't be nil");
	
	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	
	XCTAssertTrue([surveys count] == 2, @"Should be 2 surveys");
	
	ATSurvey *survey = [surveys objectAtIndex:0];
	ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
	XCTAssertTrue(question.multiline, @"Questions without multiline attribute should be multiple lines by default.");
	
	
	survey = [surveys objectAtIndex:1];
	question = [[survey questions] objectAtIndex:0];
	XCTAssertFalse(question.multiline, @"Question should be a single line.");
	
	question = [[survey questions] objectAtIndex:1];
	XCTAssertTrue(question.multiline, @"Question should be multiple lines.");
	
	[parser release], parser = nil;
}

- (void)testEmptySurvey {
	NSString *surveyString = @"{\"surveys\":[]}";
	NSData *surveyData = [surveyString dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertNotNil(surveyData, @"Survey data shouldn't be nil");

	ATSurveyParser *parser = [[ATSurveyParser alloc] init];
	NSArray *surveys = [parser parseMultipleSurveys:surveyData];
	XCTAssertNotNil(surveys, @"shouldn't be nil");
	XCTAssertTrue([surveys count] == 0, @"Should be zero surveys");
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
	
	XCTAssertEqual(ATSurveyQuestionValidationErrorTooFewAnswers, [question validateAnswer], @"Should be too few answers");
	[question addSelectedAnswerChoice:answerA];
	XCTAssertEqual(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
	question.minSelectionCount = 2;
	question.maxSelectionCount = 2;
	XCTAssertEqual(ATSurveyQuestionValidationErrorTooFewAnswers, [question validateAnswer], @"Should be too few answers");
	question.minSelectionCount = 1;
	question.maxSelectionCount = 1;
	[question addSelectedAnswerChoice:answerB];
	XCTAssertEqual(ATSurveyQuestionValidationErrorTooManyAnswers, [question validateAnswer], @"Should be too many answers");
	question.responseRequired = NO;
	XCTAssertEqual(ATSurveyQuestionValidationErrorTooManyAnswers, [question validateAnswer], @"Should be too many answers");
	[question removeSelectedAnswerChoice:answerB];
	XCTAssertEqual(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
	[question removeSelectedAnswerChoice:answerA];
	XCTAssertEqual(ATSurveyQuestionValidationErrorNone, [question validateAnswer], @"Should be valid");
}

@end
