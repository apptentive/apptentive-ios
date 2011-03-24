//
//  ATContactUpdater.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/23/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATWebClient;

NSString * const ATContactUpdaterFinished;

@interface ATContactUpdater : NSObject <NSXMLParserDelegate> {
@private
    ATWebClient *client;
    NSXMLParser *parser;
    BOOL parseInsideItem;
    NSString *parseCurrentElementName;
	NSMutableString *parseCurrentString;
    
    NSString *name;
    NSString *phone;
    NSString *email;
}
- (void)update;
- (void)cancel;
@end
