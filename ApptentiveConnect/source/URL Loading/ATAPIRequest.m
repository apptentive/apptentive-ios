//
//  ATAPIRequest.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/24/11.
//  Copyright 2011 Apptentive, Inc. All rights reserved.
//

#import "ATAPIRequest.h"
#import "ATConnect.h"
#import "ATConnect+Debugging.h"
#import "ATConnect_Private.h"
#import "ATConnectionManager.h"
#import "ATJSONSerialization.h"
#import "ATURLConnection.h"
#import "ATWebClient.h"
#import "ATWebClient_Private.h"

NSString *const ATAPIRequestStatusChanged = @"ATAPIRequestStatusChanged";

@interface ATAPIRequest ()

@property (strong, nonatomic) ATURLConnection *connection;
@property (strong, nonatomic) NSString *channelName;
@property (assign, nonatomic) BOOL cancelled;

@end


@implementation ATAPIRequest

- (id)initWithConnection:(ATURLConnection *)aConnection channelName:(NSString *)aChannelName {
	if ((self = [super init])) {
		_connection = aConnection;
		_connection.delegate = self;
		_channelName = aChannelName;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	if (_connection) {
		_connection.delegate = nil;
		[[ATConnectionManager sharedSingleton] cancelConnection:_connection inChannel:_channelName];
	}
}

- (void)start {
	@synchronized(self) {
		if (_connection) {
			[[ATConnectionManager sharedSingleton] addConnection:self.connection toChannel:self.channelName];
			[[ATConnectionManager sharedSingleton] start];
		}
	}
}

- (void)cancel {
	@synchronized(self) {
		_cancelled = YES;
		if (_connection) {
			[[ATConnectionManager sharedSingleton] cancelConnection:self.connection inChannel:self.channelName];
		}
	}
}

- (void)showAlert {
	if (self.failed) {
#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:self.errorTitle message:self.errorMessage delegate:nil cancelButtonTitle:ATLocalizedString(@"Close", nil) otherButtonTitles:nil];
		[alert show];
#endif
	}
}

#pragma mark ATURLConnection Delegates
- (void)connectionFinishedSuccessfully:(ATURLConnection *)sender {
	@synchronized(self) {
		if (self.cancelled) return;
	}
	NSInteger statusCode = sender.statusCode;
	_expiresMaxAge = [sender expiresMaxAge];
	switch (statusCode) {
		case 200:
		case 201:
		case 204:
		case 400: // rate limit reached
		case 403: // whatevs, probably private feed
			break;
		case 401:
			_failed = YES;
			_errorTitle = ATLocalizedString(@"Authentication Failed", @"");
			_errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
			break;
		case 422:
			_failed = YES;
			_errorTitle = ATLocalizedString(@"Unprocessable Entity", @"");
			_errorMessage = ATLocalizedString(@"The request was well-formed but was unable to be followed due to semantic errors.", @"");
			break;
		case 304:
			break;
		default:
			_failed = YES;
			_errorTitle = ATLocalizedString(@"Server error.", @"");
			_errorMessage = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
			break;
	}

	NSObject *result = nil;
	do { // once
		NSData *d = [sender responseData];

		if (self.failed) {
			NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
			if (responseString != nil) {
				_errorResponse = responseString;
				responseString = nil;
			}
			ATLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
			ATLogInfo(@"Status was: %d", sender.statusCode);
			if (sender.statusCode == 401) {
				ATLogError(@"Your Apptentive API key may not be set correctly!");
			}
			if (sender.statusCode == 422) {
				ATLogError(@"API Request was sent with malformed data");
			}
			if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogHTTPFailures ||
				[ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
				ATLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
				ATLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
			}
		} else if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
			ATLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
			ATLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
		}

		if (!d) break;
		if (self.returnType == ATAPIRequestReturnTypeData) {
			result = d;
			break;
		}

		NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
		if (!s) break;
		if (self.returnType == ATAPIRequestReturnTypeString) {
			result = s;
			break;
		}

		if (self.returnType == ATAPIRequestReturnTypeJSON && statusCode != 204) {
			NSError *error = nil;
			id json = [ATJSONSerialization JSONObjectWithString:s error:&error];
			if (!json) {
				_failed = YES;
				_errorTitle = ATLocalizedString(@"Invalid response from server.", @"");
				_errorMessage = ATLocalizedString(@"Server did not return properly formatted JSON.", @"");
				ATLogError(@"Invalid JSON: %@", error);
			}
			result = json;
			break;
		}
	} while (NO);

	if (self.delegate) {
		if (self.failed) {
			[self.delegate at_APIRequestDidFail:self];
		} else {
			[self.delegate at_APIRequestDidFinish:self result:result];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}

- (void)connectionFailed:(ATURLConnection *)sender {
	@synchronized(self) {
		if (self.cancelled) return;
	}
	_failed = YES;
	if (sender.failedAuthentication || sender.statusCode == 401) {
		_errorTitle = ATLocalizedString(@"Authentication Failed", @"");
		_errorMessage = ATLocalizedString(@"Wrong username and/or password.", @"");
	} else {
		_errorTitle = ATLocalizedString(@"Network Connection Error", @"");
		_errorMessage = [sender.connectionError localizedDescription];
	}
	NSData *d = [sender responseData];
	NSString *responseString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
	if (responseString != nil) {
		_errorResponse = responseString;
		responseString = nil;
	}

	if ([ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogHTTPFailures ||
		[ATConnect sharedConnection].debuggingOptions & ATConnectDebuggingOptionsLogAllHTTPRequests) {
		ATLogError(@"Connection failed. %@, %@", self.errorTitle, self.errorMessage);
		ATLogInfo(@"Status was: %d", sender.statusCode);
		ATLogDebug(@"Request was:\n%@", [self.connection requestAsString]);
		ATLogDebug(@"Response was:\n%@", [self.connection responseAsString]);
	}
	if (self.delegate) {
		[self.delegate at_APIRequestDidFail:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}

- (void)connectionDidProgress:(ATURLConnection *)sender {
	_percentageComplete = sender.percentComplete;
	if (self.delegate && [self.delegate respondsToSelector:@selector(at_APIRequestDidProgress:)]) {
		[self.delegate at_APIRequestDidProgress:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ATAPIRequestStatusChanged object:self];
}
@end
