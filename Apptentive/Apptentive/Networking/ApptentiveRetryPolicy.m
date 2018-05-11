//
//  ApptentiveRetryPolicy.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/2/18.
//  Copyright © 2018 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRetryPolicy.h"

@implementation ApptentiveRetryPolicy

@synthesize retryDelay = _retryDelay;

- (instancetype)initWithInitialBackoff:(NSTimeInterval)initialBackoff base:(float)base {
	self = [super init];

	if (self) {
		_initialBackoff = initialBackoff;
		_base = base;
		_shouldAddJitter = YES;
		_cap = DBL_MAX;

		[self resetRetryDelay];
	}

	return self;
}

- (BOOL)shouldRetryRequestWithStatusCode:(NSInteger)statusCode {
	return [self.retryStatusCodes containsIndex:statusCode];
}

- (void)increaseRetryDelay {
	_retryDelay = _retryDelay * self.base;
}

- (void)resetRetryDelay {
	_retryDelay = self.initialBackoff;
}

- (NSTimeInterval)retryDelay {
	double jitter = self.shouldAddJitter ? ((double)rand() / RAND_MAX) : 1.0;
	double cappedRetryDelay = fmin(self.cap, _retryDelay);

	return cappedRetryDelay * jitter;
}

@end
