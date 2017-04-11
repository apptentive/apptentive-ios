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

- (instancetype)initWithBaseURL:(NSURL *)baseURL SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform {
	self = [super init];

	if (self) {
		if (baseURL == nil || SDKVersion == nil || platform == nil) {
			ApptentiveLogError(@"ApptentiveNetworkQueue: One or more required initializer parameters was nil");
			return nil;
		}

		_baseURL = baseURL;

		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.HTTPAdditionalHeaders = @{
			@"Accept": @"application/json",
			@"Accept-Encoding": @"gzip",
			@"Accept-Charset": @"utf-8",
			@"User-Agent": [NSString stringWithFormat:@"ApptentiveConnect/%@ (%@)", SDKVersion, platform],
		};

		_URLSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];

		[self resetBackoffDelay];
	}

	return self;
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
