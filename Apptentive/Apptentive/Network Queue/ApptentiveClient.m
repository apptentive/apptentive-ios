//
//  ApptentiveClient.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/24/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClient.h"
#import "ApptentiveMessageGetRequest.h"
#import "ApptentiveConfigurationRequest.h"
#import "ApptentiveConversationRequest.h"

#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageSendRequest.h"

#define APPTENTIVE_MIN_BACKOFF_DELAY 1.0
#define APPTENTIVE_BACKOFF_MULTIPLIER 2.0


@implementation ApptentiveClient

@synthesize URLSession = _URLSession;
@synthesize backoffDelay = _backoffDelay;

- (instancetype)initWithBaseURL:(NSURL *)baseURL appKey:(nonnull NSString *)appKey appSignature:(nonnull NSString *)appSignature {
	self = [super init];

	if (self) {
		_baseURL = baseURL;
        _appKey = appKey;
        _appSignature = appSignature;
		_operationQueue = [[NSOperationQueue alloc] init];

		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.HTTPAdditionalHeaders = @{
			@"Accept": @"application/json",
			@"Accept-Encoding": @"gzip",
			@"Accept-Charset": @"utf-8",
			@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (iOS)", kApptentiveVersionString],
		};

		_URLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];

		[self resetBackoffDelay];
	}

	return self;
}

#pragma mark - Request operation data source

- (void)increaseBackoffDelay {
	@synchronized(self) {
		_backoffDelay *= APPTENTIVE_BACKOFF_MULTIPLIER;
	}
}

- (void)resetBackoffDelay {
	@synchronized(self) {
		_backoffDelay = APPTENTIVE_MIN_BACKOFF_DELAY;
	}
}

#pragma mark - Creating request operations

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request delegate:(id<ApptentiveRequestOperationDelegate>)delegate {
	return [self requestOperationWithRequest:request authToken:self.authToken delegate:delegate];
}

- (ApptentiveRequestOperation *)requestOperationWithRequest:(id<ApptentiveRequest>)request authToken:(NSString *)authToken delegate:(id<ApptentiveRequestOperationDelegate>)delegate {
	NSURL *URL = [NSURL URLWithString:request.path relativeToURL:self.baseURL];

	NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:URL];
	URLRequest.HTTPBody = request.payload;
	URLRequest.HTTPMethod = request.method;
	[URLRequest addValue:request.contentType forHTTPHeaderField:@"Content-Type"];
	[URLRequest addValue:request.apiVersion forHTTPHeaderField:@"X-API-Version"];
    [URLRequest addValue:_appKey forHTTPHeaderField:@"APPTENTIVE-APP-KEY"];
    [URLRequest addValue:_appSignature forHTTPHeaderField:@"APPTENTIVE-APP-SIGNATURE"];
    if (authToken) {
        [URLRequest addValue:[@"OAuth " stringByAppendingString:authToken] forHTTPHeaderField:@"Authorization"];
    }

	return [[ApptentiveRequestOperation alloc] initWithURLRequest:URLRequest delegate:delegate dataSource:self];
}

@end
