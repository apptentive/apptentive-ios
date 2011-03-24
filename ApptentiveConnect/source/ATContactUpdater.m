//
//  ATContactUpdater.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/23/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATContactUpdater.h"
#import "ATContactStorage.h"
#import "ATWebClient.h"

NSString * const ATContactUpdaterFinished = @"ATContactUpdaterFinished";

@interface ATContactUpdater (Private)
- (void)infoDidLoad:(ATWebClient *)sender result:(id)result;
- (void)processResult:(NSString *)xmlContactInfo;
- (void)saveResult;
@end

@interface ATContactUpdater ()
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
@end

@implementation ATContactUpdater
@synthesize name, email, phone;

- (id)init {
    if ((self = [super init])) {
        parseCurrentString = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)dealloc {
    [parseCurrentString release];
    parseCurrentString = nil;
    self.name = nil;
    self.email = nil;
    self.phone = nil;
    [parser release];
    parser = nil;
    [self cancel];
    [super dealloc];
}

- (void)update {
    [self cancel];
    client = [[ATWebClient alloc] initWithTarget:self action:@selector(infoDidLoad:result:)];
    [client getContactInfo];
    
}

- (void)cancel {
    if (client) {
        [client cancel];
        [client release];
        client = nil;
    }
}

#pragma mark NSXMLParserDelegate Methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"feedback"]) {
        parseInsideItem = YES;
		return;
	} else if (parseInsideItem) {
		parseCurrentElementName = elementName;
		[parseCurrentString replaceCharactersInRange:NSMakeRange(0, [parseCurrentString length]) withString:@""];
	}
}

- (void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	if ([elementName isEqualToString:@"feedback"]) {
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
    [parser release];
    parser = nil;
    [self saveResult];
}

@end

@implementation ATContactUpdater (Private)
- (void)infoDidLoad:(ATWebClient *)sender result:(id)result {
	@synchronized (self) {
        if (sender.failed) {
            NSLog(@"Request failed: %@, %@", sender.errorTitle, sender.errorMessage);
        } else if ([result isKindOfClass:[NSString class]]) {
            [self processResult:(NSString *)result];
        } else {
            NSLog(@"Contact result is not NSString!");
        }
	}
}

- (void)processResult:(NSString *)xmlContactInfo {
    if (parser) {
        [parser abortParsing];
        [parser release];
        parser = nil;
    }
    parser = [[NSXMLParser alloc] initWithData:[xmlContactInfo dataUsingEncoding:NSUTF8StringEncoding]];
    [parser setDelegate:self];
    [parser parse];
}

- (void)saveResult {
    ATContactStorage *storage = [ATContactStorage sharedContactStorage];
    if (name) storage.name = self.name;
    if (email) storage.email = self.email;
    if (phone) storage.phone = self.phone;
    [storage save];
    [[NSNotificationCenter defaultCenter] postNotificationName:ATContactUpdaterFinished object:self];
}
@end
