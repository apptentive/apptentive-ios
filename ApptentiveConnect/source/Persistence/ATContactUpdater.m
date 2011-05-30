//
//  ATContactUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/23/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATContactUpdater.h"
#import "ATContactStorage.h"
#import "ATWebClient.h"

NSString * const ATContactUpdaterFinished = @"ATContactUpdaterFinished";

@interface ATContactUpdater (Private)
- (void)processResult:(NSData *)xmlContactInfo;
@end

@implementation ATContactUpdater
- (void)dealloc {
    [self cancel];
    [super dealloc];
}

- (void)update {
    [self cancel];
    request = [[[ATWebClient sharedClient] requestForGettingContactInfo] retain];
    request.delegate = self;
    [request start];
}

- (void)cancel {
    if (request) {
        request.delegate = nil;
        [request cancel];
        [request release], request = nil;
    }
}

#pragma mark ATATIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(id)result {
    @synchronized (self) {
        if ([result isKindOfClass:[NSData class]]) {
            [self processResult:(NSData *)result];
        } else {
            NSLog(@"Contact result is not NSData!");
        }
    }
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
    // pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
    @synchronized(self) {
        NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
    }
}
@end

@implementation ATContactUpdater (Private)
- (void)processResult:(NSData *)xmlContactInfo {
    if (parser) {
        [parser abortParsing];
        [parser release];
        parser = nil;
    }
    parser = [[ATContactParser alloc] init];
    if ([parser parse:xmlContactInfo]) {
        ATContactStorage *storage = [ATContactStorage sharedContactStorage];
        if (parser.name) storage.name = parser.name;
        if (parser.email) storage.email = parser.email;
        if (parser.phone) storage.phone = parser.phone;
        [storage save];
        [[NSNotificationCenter defaultCenter] postNotificationName:ATContactUpdaterFinished object:self];
    }
}
@end

@implementation ATContactParser
@synthesize name, phone, email;

- (id)init {
    if ((self = [super init])) {
        parseCurrentString = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.phone = nil;
    self.email = nil;
    [parseCurrentString release];
    parseCurrentString = nil;
    [parser release];
    parser = nil;
    [super dealloc];
}

- (BOOL)parse:(NSData *)xmlData {
    [self abortParsing];
    self.name = nil;
    self.phone = nil;
    self.email = nil;
    parser = [[NSXMLParser alloc] initWithData:xmlData];
    [parser setDelegate:self];
    return [parser parse];
}

- (void)abortParsing {
    if (parser) {
        [parser abortParsing];
        [parser release];
        parser = nil;
    }
}

- (NSError *)parserError {
    return [parser parserError];
}

#pragma mark NSXMLParserDelegate Methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"contact"]) {
        parseInsideItem = YES;
		return;
	} else if (parseInsideItem) {
		parseCurrentElementName = elementName;
		[parseCurrentString replaceCharactersInRange:NSMakeRange(0, [parseCurrentString length]) withString:@""];
	}
}

- (void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"contact"]) {
		parseInsideItem = NO;
		return;
	} else if (parseInsideItem && parseCurrentElementName) {
        NSString *currentText = [[NSString alloc] initWithString:parseCurrentString];
        if ([parseCurrentElementName isEqualToString:@"name"]) {
            self.name = currentText;
        } else if ([parseCurrentElementName isEqualToString:@"email-address"]) {
            self.email = currentText;
        } else if ([parseCurrentElementName isEqualToString:@"phone-number"]) {
            self.phone = currentText;
        }
        [currentText release];
        
		parseCurrentElementName = nil;
        [parseCurrentString deleteCharactersInRange:NSMakeRange(0, [parseCurrentString length])];
	}
}

- (void)parser:(NSXMLParser *)aParser foundCharacters:(NSString *)string {
	if (parseInsideItem && parseCurrentElementName) {
		[parseCurrentString appendString:string];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)aParser {
}
@end


