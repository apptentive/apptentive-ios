//
//  ApptentiveNetworkQueue.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveNetworkQueue.h"

#define APPTENTIVE_MIN_BACKOFF_DELAY 1.0
#define APPTENTIVE_BACKOFF_MULTIPLIER 2.0


@implementation ApptentiveNetworkQueue

@synthesize baseURL = _baseURL;
@synthesize URLSession = _URLSession;
@synthesize backoffDelay = _backoffDelay;

- (instancetype)initWithBaseURL:(NSURL *)baseURL token:(NSString *)token SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform {
	self = [super init];

	if (self) {
		_baseURL = baseURL;
		_token = token;

		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.HTTPAdditionalHeaders = @{
			@"Accept": @"application/json",
			@"Accept-Encoding": @"gzip",
			@"Accept-Charset": @"utf-8",
			@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (%@)", SDKVersion, platform],
			@"Authorization": [@"OAuth " stringByAppendingString:token]
		};

		_URLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];

		[self resetBackoffDelay];
	}

	return self;
}

- (void)setToken:(NSString *)token {
	NSURLSessionConfiguration *configuration = self.URLSession.configuration;
	NSMutableDictionary *additionalHeaders = [configuration.HTTPAdditionalHeaders mutableCopy];
	additionalHeaders[@"Authorization"] = [@"OAuth " stringByAppendingString:token];
	configuration.HTTPAdditionalHeaders = additionalHeaders;

	_URLSession = [NSURLSession sessionWithConfiguration:configuration];
}

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

@end
