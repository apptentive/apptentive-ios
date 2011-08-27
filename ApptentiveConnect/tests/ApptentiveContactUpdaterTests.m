//
//  ApptentiveContactUpdaterTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/24/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ApptentiveContactUpdaterTests.h"
#import "ATContactUpdater.h"


@implementation ApptentiveContactUpdaterTests

- (void)testContactParsing {
    NSString *contactResponseString = @"{"
        @"\"name\":\"Andrew\",\n"
        @"\"uuid\":\"46D40D5E-C11C-5E62-BD1F-BA7A800BBDDD\",\n"
        @"\"email\":\"wooster@example.com\"\n"
        @"}\n";
    NSData *contactData = [contactResponseString dataUsingEncoding:NSUTF8StringEncoding];
    
    ATContactParser *parser = [[ATContactParser alloc] init];
    if ([parser parse:contactData]) {
        STAssertEqualObjects(parser.name, @"Andrew", @"%@ != %@", parser.name, @"Andrew");
        STAssertEqualObjects(parser.phone, nil, @"%@ != %@", parser.phone, @"Andrew");
        STAssertEqualObjects(parser.email, @"wooster@example.com", @"%@ != %@", parser.email, @"wooster@example.com");
    } else {
        STFail(@"Parsing failed %@", [parser parserError]);
    }
    
    NSString *phoneOnly = @""
        @"{\n"
        @"\"uuid\":\"46D40D5E-C11C-5E62-BD1F-BA7A800BBDDD\",\n"
        @"\"phone_number\":\"111-222-3333\"\n"
        @"}\n";
    NSData *phoneData = [phoneOnly dataUsingEncoding:NSUTF8StringEncoding];
    if ([parser parse:phoneData]) {
        STAssertEqualObjects(parser.name, nil, @"%@ != nil", parser.name);
        STAssertEqualObjects(parser.phone, @"111-222-3333", @"%@ != %@", parser.phone, @"111-222-3333");
        STAssertEqualObjects(parser.email, nil, @"%@ != nil", parser.email);
    } else {
        STFail(@"Parsing failed %@", [parser parserError]);
    }
    [parser release];
    parser = nil;
}
@end
