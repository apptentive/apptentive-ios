//
//  ClauseTests.m
//  ApptentiveTests
//
//  Created by Frank Schmitt on 3/9/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ApptentiveConversation.h"
#import "ApptentiveDevice.h"
#import "ApptentiveIndentPrinter.h"
#import "ApptentiveFalseClause.h"
#import "ApptentiveAndClause.h"
#import "ApptentiveOrClause.h"
#import "ApptentiveNotClause.h"

@interface ClauseTests : XCTestCase

@property (nonatomic, strong) ApptentiveConversation *conversation;
@property (nonatomic, strong) ApptentiveIndentPrinter *indentPrinter;

@end


@interface ApptentiveTrueClause : ApptentiveClause
@end


@implementation ApptentiveTrueClause

- (BOOL)criteriaMetForConversation:(ApptentiveConversation *)conversation indentPrinter:(ApptentiveIndentPrinter *)indentPrinter {
	[indentPrinter appendFormat:@"- Mock ”always true” clause -> true"];
	return YES;
}

@end


@interface ApptentiveAndClause ()

@property (readonly, nonatomic) NSMutableArray *subClauses;

@end


@interface ApptentiveOrClause ()

@property (readonly, nonatomic) NSMutableArray *subClauses;

@end


@interface ApptentiveNotClause ()

@property (readwrite, nonatomic) ApptentiveClause *subClause;

@end


@implementation ClauseTests

- (void)setUp {
    [super setUp];

	[ApptentiveDevice getPermanentDeviceValues];

	self.conversation = [[ApptentiveConversation alloc] initWithState:ApptentiveConversationStateAnonymous];

	self.indentPrinter = [[ApptentiveIndentPrinter alloc] init];
}

- (void)tearDown {
	NSLog(@"%@", self.indentPrinter.output);

    [super tearDown];
}

- (void)testFalse {
	ApptentiveFalseClause *clause = [[ApptentiveFalseClause alloc] init];

	XCTAssertFalse([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);
}

- (void)testTrue {
	ApptentiveTrueClause *clause = [[ApptentiveTrueClause alloc] init];

	XCTAssertTrue([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);
}

- (void)testAnd {
	ApptentiveAndClause *clause = [[ApptentiveAndClause alloc] init];

	XCTAssertTrue([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);

	[clause.subClauses addObject:[[ApptentiveTrueClause alloc] init]];

	XCTAssertTrue([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);

	[clause.subClauses addObject:[[ApptentiveFalseClause alloc] init]];

	XCTAssertFalse([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);
}

- (void)testOr {
	ApptentiveOrClause *clause = [[ApptentiveOrClause alloc] init];

	XCTAssertFalse([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);

	[clause.subClauses addObject:[[ApptentiveFalseClause alloc] init]];

	XCTAssertFalse([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);

	[clause.subClauses addObject:[[ApptentiveTrueClause alloc] init]];

	XCTAssertTrue([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);
}

- (void)testNot {
	ApptentiveNotClause *clause = [[ApptentiveNotClause alloc] init];
	clause.subClause = [[ApptentiveFalseClause alloc] init];

	XCTAssertTrue([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);

	clause.subClause = [[ApptentiveTrueClause alloc] init];

	XCTAssertFalse([clause criteriaMetForConversation:self.conversation indentPrinter:self.indentPrinter]);
}

@end
