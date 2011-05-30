//
//  ATContactUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/23/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATAPIRequest.h"

@class ATContactParser;

NSString * const ATContactUpdaterFinished;

@interface ATContactUpdater : NSObject <ATAPIRequestDelegate> {
@private
    ATAPIRequest *request;
    ATContactParser *parser;
}
- (void)update;
- (void)cancel;
@end


@interface ATContactParser : NSObject <NSXMLParserDelegate> {
@private
    NSXMLParser *parser;
    BOOL parseInsideItem;
    NSString *parseCurrentElementName;
	NSMutableString *parseCurrentString;
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *email;
- (BOOL)parse:(NSData *)xmlData;
- (void)abortParsing;
- (NSError *)parserError;
@end
