//
//  ATSurveyTests.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 3/3/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveSurveyViewModel.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveSurveyMetrics.h"


@interface ApptentiveSurveyTests : XCTestCase <ATSurveyViewModelDelegate>

@property (strong, nonatomic) ApptentiveSurveyViewModel *viewModel;
@property (strong, nonatomic) NSMutableSet *answeredQuestions;
@property (strong, nonatomic) NSDictionary *didHideUserInfo;
@property (assign, nonatomic) BOOL validationChanged;
@property (assign, nonatomic) NSMutableSet *deselectedIndexPaths;

@end


@implementation ApptentiveSurveyTests

- (void)setUp {
	[super setUp];

	NSURL *JSONURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Survey" withExtension:@"json"];
	NSData *JSONData = [NSData dataWithContentsOfURL:JSONURL];
	NSError *error;
	NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];

	if (!JSONDictionary) {
		NSLog(@"Error reading JSON: %@", error);
	} else {
		ApptentiveInteraction *surveyInteraction = [ApptentiveInteraction interactionWithJSONDictionary:JSONDictionary];
		self.viewModel = [[ApptentiveSurveyViewModel alloc] initWithInteraction:surveyInteraction];
		self.viewModel.delegate = self;

		self.answeredQuestions = [NSMutableSet set];
		self.deselectedIndexPaths = [NSMutableSet set];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(answeredQuestion:) name:ATSurveyDidAnswerQuestionNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHide:) name:ATSurveyDidHideWindowNotification object:nil];
	}
}

- (void)tearDown {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.viewModel.delegate = nil;

	[super tearDown];
}

- (void)answeredQuestion:(NSNotification *)notification {
	[self.answeredQuestions addObject:notification.userInfo[ATSurveyMetricsSurveyQuestionIDKey]];
}

- (void)didHide:(NSNotification *)notification {
	self.didHideUserInfo = notification.userInfo;
}

- (void)viewModelValidationChanged:(ApptentiveSurveyViewModel *)viewModel {
	self.validationChanged = YES;
}

- (void)viewModel:(ApptentiveSurveyViewModel *)viewModel didDeselectAnswerAtIndexPath:(NSIndexPath *)indexPath {
	[self.deselectedIndexPaths addObject:indexPath];
}

- (void)testBasics {
	XCTAssertNotNil(self.viewModel);
	XCTAssertNotNil(self.viewModel.interaction);
	XCTAssertNotNil(self.viewModel.survey);

	XCTAssertEqualObjects([self.viewModel textOfQuestionAtIndex:4], @"Multiselect Optional With Limits");
	XCTAssertEqualObjects([self.viewModel textOfAnswerAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:4]], @"C");
	XCTAssertEqual([self.viewModel typeOfQuestionAtIndex:3], ATSurveyQuestionTypeMultipleSelect);
	XCTAssertEqualObjects(self.viewModel.greeting, @"Please help us see how each question is formatted when returning a survey response to the server.");
	XCTAssertEqualObjects(self.viewModel.submitButtonText, @"Submit");
	XCTAssertEqualObjects([self.viewModel instructionTextOfQuestionAtIndex:1], @"required—select one");
}

- (void)testRadioButtons {
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

	XCTAssertTrue([self.deselectedIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
	XCTAssertFalse([self.viewModel answerAtIndexPathIsSelected:[NSIndexPath indexPathForItem:0 inSection:0]]);
	[self.deselectedIndexPaths removeAllObjects];

	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

	XCTAssertTrue([self.viewModel answerAtIndexPathIsSelected:[NSIndexPath indexPathForItem:1 inSection:0]]);
	XCTAssertEqual(self.deselectedIndexPaths.count, 0);
}

- (void)testValidation {
	XCTAssertFalse([self.viewModel validate:YES]);

	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

	[self.viewModel setText:@"Foo" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
	[self.viewModel setText:@"Bar" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

	XCTAssertTrue([self.viewModel validate:YES]);
	XCTAssertTrue(self.validationChanged);
	self.validationChanged = NO;

	[self.viewModel deselectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

	XCTAssertFalse([self.viewModel validate:YES]);
	XCTAssertTrue(self.validationChanged);
	self.validationChanged = NO;

	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:5]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:5]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:5]];

	XCTAssertFalse([self.viewModel validate:YES]);
	XCTAssertTrue(self.validationChanged);
	self.validationChanged = NO;

	[self.viewModel deselectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

	XCTAssertTrue([self.viewModel validate:YES]);
	XCTAssertTrue(self.validationChanged);
	self.validationChanged = NO;

	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

	XCTAssertFalse(self.validationChanged);

	[self.viewModel setText:@" " forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];

	XCTAssertFalse([self.viewModel validate:YES]);
	XCTAssertTrue(self.validationChanged);
	self.validationChanged = NO;
}

- (void)testAnswers {
	XCTAssertEqualObjects(self.viewModel.answers, @{});

	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

	[self.viewModel setText:@" Foo " forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
	[self.viewModel setText:@" Bar\n" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

	NSLog(@"answers are: %@", self.viewModel.answers);

	XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f3300000b"], @"56d49499c719925f3300000c");
	XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000011"], @[@"56d49499c719925f33000012"]);
	XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000019"], @[@"56d49499c719925f3300001a"]);
	XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f3300001f"], @"Foo");
	XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000021"], @"Bar");
}

- (void)testMetrics {
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

	[self.viewModel commitChangeAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
	[self.viewModel commitChangeAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

	XCTAssertEqual(self.answeredQuestions.count, 5);
	XCTAssertTrue([self.answeredQuestions containsObject:@"56d49499c719925f3300000b"]);
	XCTAssertTrue([self.answeredQuestions containsObject:@"56d49499c719925f33000011"]);
	XCTAssertTrue([self.answeredQuestions containsObject:@"56d49499c719925f33000019"]);
	XCTAssertTrue([self.answeredQuestions containsObject:@"56d49499c719925f3300001f"]);
	XCTAssertTrue([self.answeredQuestions containsObject:@"56d49499c719925f33000021"]);

	[self.viewModel didSubmit];

	XCTAssertEqualObjects(self.didHideUserInfo[ATSurveyMetricsEventKey], @(ATSurveyEventTappedSend));

	[self.viewModel didCancel];

	XCTAssertEqualObjects(self.didHideUserInfo[ATSurveyMetricsEventKey], @(ATSurveyEventTappedCancel));
}

@end
