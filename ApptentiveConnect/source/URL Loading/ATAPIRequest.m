//
//  ATAPIRequest.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAPIRequest.h"
#import "ATConnect.h"
#import "ATConnectionManager.h"
#import "ATURLConnection.h"

#ifdef SUPPORT_JSON
#import "JSON.h"
#endif

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NSString *const ATAPIRequestStatusChanged = @"ATAPIRequestStatusChanged";

@implementation ATAPIRequest
@synthesize returnType, failed, errorTitle, errorMessage, timeoutInterval, delegate;

- (id)initWithConnection:(ATURLConnection *)aConnection channelName:(NSString *)aChannelName {
    if ((self = [super init])) {
        connection = [aConnection retain];
        connection.delegate = self;
        channelName = [aChannelName retain];
    }
    return self;
}

- (void)dealloc {
    self.delegate = nil;
    if (connection) {
        connection.delegate = nil;
        [[ATConnectionManager sharedSingleton] cancelConnection:connection inChannel:channelName];
        [connection release], connection = nil;
    }
    self.errorTitle = nil;
    self.errorMessage = nil;
    [channelName release], channelName = nil;
    
    [super dealloc];
}

- (void)start {
    @synchronized(self) {
        if (connection) {
            [[ATConnectionManager sharedSingleton] addConnection:connection toChannel:channelName];
            [[ATConnectionManager sharedSingleton] start];
        }
    }
}

- (void)cancel {
    @synchronized(self) {
		cancelled = YES;
        if (connection) {
            [[ATConnectionManager sharedSingleton] cancelConnection:connection inChannel:channelName];
        }
	}
}

- (void)showAlert {
	if (self.failed) {
#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.errorTitle message:self.errorMessage delegate:self cancelButtonTitle:ATLocalizedString(@"Close", nil) otherButtonTitles:nil];
		[alert show];
		[alert release];
#endif
	}
}

- (float)percentageComplete {
    return percentageComplete;
}

#pragma mark ATURLConnection Delegates
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender {
	@synchronized(self) {
		if (cancelled) return;
	}
	int statusCode = sender.statusCode;
	switch (statusCode) {
		case 200:
        case 201:
		case 400: // rate limit reached
		case 403: // whatevs, probably private feed
			break;
		case 401:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Authentication Failed", @"");
			self.errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
			break;
		case 304:
			break;
		default:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Server error.", @"");
			self.errorMessage = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
			break;
	}
	
	id result = nil;
	do { // once
		NSData *d = [sender responseData];
        /*!!!!! Uncomment to debug HTTP stuff.
        if (YES) {
            NSString *a = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
            NSLog(@"request: %@", [connection requestAsString]);
            NSLog(@"a: %@", a);
        }
         */
        
		if (!d) break;
		if (self.returnType == ATAPIRequestReturnTypeData) {
			result = d;
			break;
		}
		
		NSString *s = [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] autorelease];
		if (!s) break;
		if (self.returnType == ATAPIRequestReturnTypeString) {
			result = s;
			break;
		}
        
#ifdef SUPPORT_JSON
		if (self.returnType == ATAPIRequestReturnTypeJSON) {
			id json = [s JSONValue];
			if (!json) {
				self.failed = YES;
				self.errorTitle = ATLocalizedString(@"Invalid response from server.", @"");
				self.errorMessage = ATLocalizedString(@"Server did not return properly formatted JSON.", @"");
			}
			result = json;
			break;
		}
#endif
	} while (NO);
	
	if (delegate) {
        if (self.failed) {
            [delegate at_APIRequestDidFail:self];
        } else {
            [delegate at_APIRequestDidFinish:self result:result];
        }
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}

- (void)connectionFailed:(ATURLConnection *)sender {
	@synchronized(self) {
		if (cancelled) return;
	}
	self.failed = YES;
	if (sender.failedAuthentication || sender.statusCode == 401) {
		self.errorTitle = ATLocalizedString(@"Authentication Failed", @"");
		self.errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
	} else {
		self.errorTitle = ATLocalizedString(@"Network Connection Error", @"");
		self.errorMessage = [sender.connectionError localizedDescription];
	}
	if (delegate) {
        [delegate at_APIRequestDidFail:self];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}

- (void)connectionDidProgress:(ATURLConnection *)sender {
    percentageComplete = sender.percentComplete;
    if (delegate) {
        [delegate at_APIRequestDidProgress:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}
@end
