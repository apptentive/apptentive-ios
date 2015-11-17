//
//  PayloadTest.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/16/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

@class ATEngagementManifestParser;

@interface PayloadTest : XCTestCase

@property (readonly, nonatomic) NSString *JSONFilename;
@property (strong, nonatomic) ATEngagementManifestParser *parser;
@property (strong, nonatomic) NSDictionary *targets;
@property (strong, nonatomic) NSDictionary *interactions;

@end
