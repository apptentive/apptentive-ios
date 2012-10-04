//
//  ATWebClient+MessageCenter.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATWebClient+MessageCenter.h"
#import "ATAPIRequest.h"
#import "ATURLConnection.h"
#import "ATWebClient_Private.h"

#import "PJSONKit.h"

#define kMessageCenterChannelName (@"Message Center")

@implementation ATWebClient (MessageCenter)
- (ATAPIRequest *)requestForCreatingPerson:(ATPerson *)person {
	NSError *error = nil;
	NSDictionary *postJSON = nil;
	if (person == nil) {
		postJSON = [NSDictionary dictionary];
	} else {
		postJSON = [person apiJSON];
	}
	NSString *postString = [postJSON ATJSONStringWithOptions:ATJKSerializeOptionPretty error:&error];
	if (!postString && error != nil) {
		NSLog(@"ATWebClient+MessageCenter: Error while encoding JSON: %@", error);
		return nil;
	}
	NSString *url = [self apiURLStringWithPath:@"people"];
	ATURLConnection *conn = nil;
	
	conn = [self connectionToPost:[NSURL URLWithString:url] JSON:postString];
	
	conn.timeoutInterval = 60.0;
	ATAPIRequest *request = [[ATAPIRequest alloc] initWithConnection:conn channelName:kMessageCenterChannelName];
	request.returnType = ATAPIRequestReturnTypeJSON;
	return [request autorelease];
}
@end
