//
//  ApptentiveSurveyTests.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/3/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveConversation.h"
#import "ApptentiveCount.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveInteractionUsageData.h"
#import "ApptentiveStyleSheet.h"
#import "ApptentiveSurveyViewModel.h"
#import "Apptentive_Private.h"
#import <XCTest/XCTest.h>


@interface ApptentiveSurveyTests : XCTestCase <ATSurveyViewModelDelegate>

@property (strong, nonatomic) ApptentiveSurveyViewModel *viewModel;
@property (strong, nonatomic) NSDictionary *didHideUserInfo;
@property (assign, nonatomic) BOOL validationChanged;
@property (strong, nonatomic) NSMutableSet *deselectedIndexPaths;

@end


@implementation ApptentiveSurveyTests

- (void)setUp
{
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

        self.deselectedIndexPaths = [NSMutableSet set];
    }
}

- (void)tearDown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.viewModel.delegate = nil;

    [super tearDown];
}

- (void)viewModelValidationChanged:(ApptentiveSurveyViewModel *)viewModel isValid:(BOOL)valid
{
    self.validationChanged = YES;
}

- (void)viewModel:(ApptentiveSurveyViewModel *)viewModel didDeselectAnswerAtIndexPath:(NSIndexPath *)indexPath
{
    [self.deselectedIndexPaths addObject:indexPath];
}

- (void)testBasics
{
    XCTAssertNotNil(self.viewModel);
    XCTAssertNotNil(self.viewModel.interaction);
    XCTAssertNotNil(self.viewModel.survey);

    XCTAssertEqualObjects([self.viewModel textOfQuestionAtIndex:4], @"Multiselect Optional With Limits");
    XCTAssertEqualObjects([self.viewModel textOfChoiceAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:4]], @"C");
    XCTAssertEqual([self.viewModel typeOfQuestionAtIndex:3], ATSurveyQuestionTypeMultipleSelect);
    XCTAssertEqualObjects(self.viewModel.greeting, @"Please help us see how each question is formatted when returning a survey response to the server.");
    XCTAssertEqualObjects(self.viewModel.submitButtonText, @"Submit");
    XCTAssertEqualObjects([self.viewModel instructionTextOfQuestionAtIndex:1].string, @"Required – select one");
    NSIndexPath *otherIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    XCTAssertEqual([self.viewModel typeOfAnswerAtIndexPath:otherIndexPath], ApptentiveSurveyAnswerTypeOther, @"Last answer of first question should be of type “Other”.");
    XCTAssertEqualObjects([self.viewModel placeholderTextOfAnswerAtIndexPath:otherIndexPath].string, @"Other Placeholder");
}

- (void)testRadioButtons
{
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

    XCTAssertTrue([self.deselectedIndexPaths containsObject:[NSIndexPath indexPathForItem:0 inSection:0]]);
    XCTAssertFalse([self.viewModel answerIsSelectedAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]);
    [self.deselectedIndexPaths removeAllObjects];

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

    XCTAssertTrue([self.viewModel answerIsSelectedAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]]);
    XCTAssertEqual(self.deselectedIndexPaths.count, (NSUInteger)0);
}

- (void)testValidation
{
    XCTAssertFalse([self.viewModel validate:YES]);

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

    [self.viewModel setText:@"Foo" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
    [self.viewModel setText:@"Bar" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:11]];

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

    XCTAssertTrue([self.viewModel validate:NO]);
    XCTAssertFalse(self.validationChanged);

    XCTAssertFalse([self.viewModel validate:YES]);
    XCTAssertTrue(self.validationChanged);
    self.validationChanged = NO;

    [self.viewModel setText:@"Foo" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
    XCTAssertTrue([self.viewModel validate:YES]);

    NSIndexPath *optionalOtherIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.viewModel selectAnswerAtIndexPath:optionalOtherIndexPath];
    XCTAssertTrue([self.viewModel validate:YES]);

    NSIndexPath *requiredOtherIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    [self.viewModel selectAnswerAtIndexPath:requiredOtherIndexPath];
    XCTAssertFalse([self.viewModel validate:YES]);
    XCTAssertFalse([self.viewModel answerIsValidAtIndexPath:requiredOtherIndexPath]);
    XCTAssertFalse([self.viewModel answerIsValidForQuestionAtIndex:requiredOtherIndexPath.section]);

    [self.viewModel setText:@"Foo" forAnswerAtIndexPath:requiredOtherIndexPath];
    XCTAssertTrue([self.viewModel answerIsValidAtIndexPath:requiredOtherIndexPath]);
    XCTAssertTrue([self.viewModel answerIsValidForQuestionAtIndex:requiredOtherIndexPath.section]);
    XCTAssertTrue([self.viewModel validate:YES]);
    XCTAssertTrue([self.viewModel answerIsValidAtIndexPath:requiredOtherIndexPath]);
    XCTAssertTrue([self.viewModel answerIsValidForQuestionAtIndex:requiredOtherIndexPath.section]);
}

- (void)testAnswers
{
    XCTAssertEqualObjects(self.viewModel.answers, @{});

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]];
    [self.viewModel setText:@"Other Text" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

    [self.viewModel setText:@" Foo " forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
    [self.viewModel setText:@" Bar\n" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

    NSDictionary *answer = @{ @"id" : @"56d49499c719925f3300000b",
                              @"value" : @"Other Text" };
    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f3300000b"], @[ answer ]);
    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000011"], @[ @{ @"id" : @"56d49499c719925f33000012" } ]);
    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000019"], @[ @{ @"id" : @"56d49499c719925f3300001a" } ]);

    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f3300001f"], @[ @{ @"value" : @"Foo" } ]);
    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000021"], @[ @{ @"value" : @"Bar" } ]);
}

// TODO: figure out a way to test this synchronously.
//- (void)testMetrics {
//	// Stand up a fake backend, give it time to create a session, and make it pretend that it's ready.
//	Apptentive.shared.APIKey = @"foo";
//	sleep(2);
//	[Apptentive.shared.backend setValue:@(2) forKey:@"state"]; // 2 = ATBackendStateReady
//
//	NSInteger preCount = Apptentive.shared.backend.session.engagement.codePoints[@"com.apptentive#Survey#question_response"].totalCount;
//
//	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
//	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
//	[self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];
//
//	[self.viewModel commitChangeAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
//	[self.viewModel commitChangeAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];
//
//	NSInteger postCount = Apptentive.shared.backend.session.engagement.codePoints[@"com.apptentive#Survey#question_response"].totalCount;
//
//	XCTAssertEqual(postCount - preCount, 5);
//}

- (void)testTagForIndexPath
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:69 inSection:369];
    NSInteger tag = [self.viewModel textFieldTagForIndexPath:indexPath];
    NSIndexPath *resultIndexPath = [self.viewModel indexPathForTextFieldTag:tag];

    XCTAssertEqualObjects(indexPath, resultIndexPath, @"Index paths should survive being tagged and untagged");
}

- (void)testRange
{
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:10]];

    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000022"], @[ @{ @"value" : @-3 } ]);

    XCTAssertFalse([self.viewModel validate:YES]);

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:3]];
    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:5]];

    [self.viewModel setText:@"Foo" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:7]];
    [self.viewModel setText:@"Bar" forAnswerAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:9]];

    [self.viewModel selectAnswerAtIndexPath:[NSIndexPath indexPathForItem:5 inSection:11]];

    XCTAssertEqualObjects(self.viewModel.answers[@"56d49499c719925f33000023"], @[ @{ @"value" : @5 } ]);

    XCTAssertTrue([self.viewModel validate:YES]);
}

- (void)testErrorMessages
{
    XCTAssertEqualObjects([self.viewModel errorMessageAtIndex:1], @"You have to select one.");
    XCTAssertEqualObjects([self.viewModel errorMessageAtIndex:3], @"You have to select one.");
    XCTAssertEqualObjects([self.viewModel errorMessageAtIndex:4], @"You have selected too many or too few answers.");
}

@end
