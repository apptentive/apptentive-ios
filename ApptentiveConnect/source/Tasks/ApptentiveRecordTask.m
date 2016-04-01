//
//  ATRecordTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecordTask.h"
#import "ApptentiveMetrics.h"
#import "ApptentiveMetric.h"
#import "ApptentiveWebClient.h"
#import "Apptentive_Private.h"

#define kATRecordTaskCodingVersion 1


@interface ApptentiveRecordTask ()
- (BOOL)handleLegacyRecord;

@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentiveRecordTask

+ (void)initialize {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATRecordTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATRecordTaskCodingVersion) {
			self.record = [coder decodeObjectForKey:@"record"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATRecordTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.record forKey:@"record"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		return NO;
	}
	return YES;
}

- (void)start {
	if ([self handleLegacyRecord]) {
		self.finished = YES;
		return;
	}
	if (!self.request) {
		self.request = [self.record requestForSendingRecord];
		if (self.request != nil) {
			self.request.delegate = self;
			[self.request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
}

- (void)stop {
	if (self.request) {
		self.request.delegate = nil;
		[self.request cancel];
		self.request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (self.request) {
		return [self.request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"record";
}

- (void)cleanup {
	[self.record cleanup];
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		[self stop];
		self.finished = YES;
	}
}

- (void)at_APIRequestDidProgress:(ApptentiveAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ApptentiveAPIRequest *)sender {
	@synchronized(self) {
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		self.shouldRetry = sender.shouldRetry;
		ApptentiveLogInfo(@"ApptentiveAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
	}
}

#pragma mark - Private methods

- (BOOL)handleLegacyRecord {
	if ([self.record isKindOfClass:[ApptentiveMetric class]]) {
		if ([[ApptentiveMetrics sharedMetrics] upgradeLegacyMetric:(ApptentiveMetric *)self.record]) {
			return YES;
		}
	}
	return NO;
}
@end
