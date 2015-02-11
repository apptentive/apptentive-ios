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
#import "ATJSONSerialization.h"

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
	NSString *surveyInteractionString = @"{\"priority\":1,\"criteria\":{\"interactions/536027f07724c5ba0e000026/invokes/total\":0,\"current_time\":{\"$gte\":1398810401}},\"id\":\"536027f07724c5ba0e000026\",\"type\":\"Survey\",\"configuration\":{\"name\":\"Happy Fun Test Survey\",\"description\":\"This is a fun test survey with a description like this.\",\"multiple_responses\":false,\"show_success_message\":false,\"success_message\":\"Thank you for your input.\",\"questions\":[{\"id\":\"536027f07724c5ba0e000027\",\"answer_choices\":[{\"id\":\"536027f07724c5ba0e000028\",\"value\":\"Yes\"},{\"id\":\"536027f07724c5ba0e000029\",\"value\":\"No\"},{\"id\":\"536027f07724c5ba0e00002a\",\"value\":\"Maybe\"},{\"id\":\"536027f07724c5ba0e00002b\",\"value\":\"So\"},{\"id\":\"536027f07724c5ba0e00002c\",\"value\":\"99\"},{\"id\":\"536027f07724c5ba0e00002d\",\"value\":\"100\"}],\"instructions\":\"select one\",\"value\":\"Question 1\",\"type\":\"multichoice\",\"required\":true},{\"id\":\"536027f07724c5ba0e00002e\",\"answer_choices\":[{\"id\":\"536027f07724c5ba0e00002f\",\"value\":\"Yes\"},{\"id\":\"536027f07724c5ba0e000030\",\"value\":\"No\"}],\"instructions\":\"select one\",\"value\":\"Question 2\",\"type\":\"multichoice\",\"required\":true},{\"id\":\"536027f07724c5ba0e000031\",\"answer_choices\":[{\"id\":\"536027f07724c5ba0e000032\",\"value\":\"Yes\"},{\"id\":\"536027f07724c5ba0e000033\",\"value\":\"No\"}],\"instructions\":\"select one\",\"value\":\"Question 3\",\"type\":\"multichoice\",\"required\":true}]}}";
	
	NSData *surveyInteractionData = [surveyInteractionString dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertNotNil(surveyInteractionData, @"Survey data shouldn't be nil");

	NSError *error = nil;
	id decodedObject = [ATJSONSerialization JSONObjectWithData:surveyInteractionData error:&error];
	
	XCTAssertTrue((decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]), @"should decode the interaction");
	if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
		ATSurveyParser *parser = [[ATSurveyParser alloc] init];
		ATSurvey *survey = [parser surveyWithInteraction:[ATInteraction interactionWithJSONDictionary:decodedObject]];
		
		XCTAssertTrue([survey.identifier isEqualToString:@"536027f07724c5ba0e000026"], @"id mismatch");
		XCTAssertTrue([survey.name isEqualToString:@"Happy Fun Test Survey"], @"name mismatch");
		XCTAssertTrue([survey.surveyDescription isEqualToString:@"This is a fun test survey with a description like this."], @"description mismatch");
		XCTAssertTrue([[survey questions] count] == 3 , @"Should be 3 questions");
		
		ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
		XCTAssertTrue([question.answerChoices count] == 6, @"First question should have 6 answers");
		
		[parser release], parser = nil;
	}
}

- (void)testSingleLineParsing {
	NSString *surveyInteractionString = @"{\"priority\":1,\"criteria\":{\"interactions/53604fedf895936d850105c7/invokes/total\":0,\"current_time\":{\"$gte\":1398820782}},\"id\":\"53604fedf895936d850105c7\",\"type\":\"Survey\",\"configuration\":{\"name\":\"Multi-Line Test\",\"description\":\"test multiple lines\",\"multiple_responses\":false,\"show_success_message\":false,\"success_message\":\"Thank you for your input.\",\"questions\":[{\"id\":\"53604fedf895936d850105c8\",\"value\":\"No multi line attribute.\",\"type\":\"singleline\",\"required\":true},{\"id\":\"53604fedf895936d850105c9\",\"multiline\":false,\"value\":\"Single Line\",\"type\":\"singleline\",\"required\":true},{\"id\":\"53604fedf895936d850105ca\",\"multiline\":true,\"value\":\"Multi Line\",\"type\":\"singleline\",\"required\":true}]}}";
	
	NSData *surveyInteractionData = [surveyInteractionString dataUsingEncoding:NSUTF8StringEncoding];
	XCTAssertNotNil(surveyInteractionData, @"Survey data shouldn't be nil");
	
	NSError *error = nil;
	id decodedObject = [ATJSONSerialization JSONObjectWithData:surveyInteractionData error:&error];
	
	XCTAssertTrue((decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]), @"should decode the interaction");
	if (decodedObject && [decodedObject isKindOfClass:[NSDictionary class]]) {
		ATSurveyParser *parser = [[ATSurveyParser alloc] init];
		ATSurvey *survey = [parser surveyWithInteraction:[ATInteraction interactionWithJSONDictionary:decodedObject]];

		ATSurveyQuestion *question = [[survey questions] objectAtIndex:0];
		XCTAssertTrue(question.multiline, @"Questions without multiline attribute should be multiple lines by default.");
		
		question = [[survey questions] objectAtIndex:1];
		XCTAssertFalse(question.multiline, @"Question should be a single line.");
		
		question = [[survey questions] objectAtIndex:2];
		XCTAssertTrue(question.multiline, @"Question should be multiple lines.");
		
		[parser release], parser = nil;
	}
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
