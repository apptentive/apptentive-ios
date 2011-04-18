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
    NSString *contactResponseString = @""
        @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        @"<contact>\n"
        @"  <name>Andrew</name>\n"
        @"  <uuid>46D40D5E-C11C-5E62-BD1F-BA7A800BBDDD</uuid>\n"
        @"  <email-address>wooster@example.com</email-address>\n"
        @"</contact>\n";
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
        @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        @"<contact>\n"
        @"  <uuid>46D40D5E-C11C-5E62-BD1F-BA7A800BBDDD</uuid>\n"
        @"  <phone-number>111-222-3333</phone-number>\n"
        @"</contact>\n";
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
