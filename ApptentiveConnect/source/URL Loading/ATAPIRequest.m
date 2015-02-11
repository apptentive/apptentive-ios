//
//  ATAPIRequest.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAPIRequest.h"
#import "ATConnect.h"
#import "ATConnect_Debugging.h"
#import "ATConnect_Private.h"
#import "ATConnectionManager.h"
#import "ATJSONSerialization.h"
#import "ATURLConnection.h"
#import "ATWebClient.h"
#import "ATWebClient_Private.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

NSString *const ATAPIRequestStatusChanged = @"ATAPIRequestStatusChanged";

@implementation ATAPIRequest
@synthesize returnType, failed, errorTitle, errorMessage, errorResponse, timeoutInterval, delegate;

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
	[errorTitle release], errorTitle = nil;
	[errorMessage release], errorMessage = nil;
	[errorResponse release], errorResponse = nil;
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
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.errorTitle message:self.errorMessage delegate:nil cancelButtonTitle:ATLocalizedString(@"Close", nil) otherButtonTitles:nil];
		[alert show];
		[alert release];
#endif
	}
}

- (float)percentageComplete {
	return percentageComplete;
}

- (NSTimeInterval)expiresMaxAge {
	return expiresMaxAge;
}

#pragma mark ATURLConnection Delegates
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender {
	@synchronized(self) {
		if (cancelled) return;
	}
	NSInteger statusCode = sender.statusCode;
	expiresMaxAge = [sender expiresMaxAge];
	switch (statusCode) {
		case 200:
		case 201:
		case 204:
		case 400: // rate limit reached
		case 403: // whatevs, probably private feed
			break;
		case 401:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Authentication Failed", @"");
			self.errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
			break;
		case 422:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Unprocessable Entity", @"");
			self.errorMessage = ATLocalizedString(@"The request was well-formed but was unable to be followed due to semantic errors.", @"");
			break;
		case 304:
			break;
		default:
			self.failed = YES;
			self.errorTitle = ATLocalizedString(@"Server error.", @"");
			self.errorMessage = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
			break;
	}
	
	NSObject *result = nil;
	do { // once
		NSData *d = [sender responseData];
		
		if (self.failed) {
			NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
			if (responseString != nil) {
				self.errorResponse = responseString;
				[responseString release], responseString = nil;
			}
			ATLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
			ATLogInfo(@"Status was: %d", sender.statusCode);
			if (sender.statusCode == 401) {
				ATLogDebug(@"Your Apptentive API key may not be set correctly!");
			}
			if (sender.statusCode == 422) {
				if ([[connection.targetURL absoluteString] isEqualToString:[[ATWebClient sharedClient] apiURLStringWithPath:@"events"]]) {
					ATLogWarning(@"Event was invalid; sent with malformed customData or extendedData.");
				}
			}
			if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogHTTPFailures ||
				[ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
				ATLogDebug(@"Request was:\n%@", [connection requestAsString]);
				ATLogDebug(@"Response was:\n%@", [connection responseAsString]);
			}
		} else if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
			ATLogDebug(@"Request was:\n%@", [connection requestAsString]);
			ATLogDebug(@"Response was:\n%@", [connection responseAsString]);
		}
		
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
		
		if (self.returnType == ATAPIRequestReturnTypeJSON && statusCode != 204) {
			NSError *error = nil;
			id json = [ATJSONSerialization JSONObjectWithString:s error:&error];
			if (!json) {
				self.failed = YES;
				self.errorTitle = ATLocalizedString(@"Invalid response from server.", @"");
				self.errorMessage = ATLocalizedString(@"Server did not return properly formatted JSON.", @"");
				ATLogError(@"Invalid JSON: %@", error);
			}
			result = json;
			break;
		}
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
	NSData *d = [sender responseData];
	NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	if (responseString != nil) {
		self.errorResponse = responseString;
		[responseString release], responseString = nil;
	}
	
	if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogHTTPFailures ||
		[ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
		ATLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
		ATLogInfo(@"Status was: %d", sender.statusCode);
		ATLogDebug(@"Request was:\n%@", [connection requestAsString]);
		ATLogDebug(@"Response was:\n%@", [connection responseAsString]);
	}
	if (delegate) {
		[delegate at_APIRequestDidFail:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}

- (void)connectionDidProgress:(ATURLConnection *)sender {
	percentageComplete = sender.percentComplete;
	if (delegate && [delegate respondsToSelector:@selector(at_APIRequestDidProgress:)]) {
		[delegate at_APIRequestDidProgress:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}
@end
