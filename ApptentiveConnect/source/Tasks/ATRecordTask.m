//
//  ATRecordTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 1/10/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATRecordTask.h"
#import "ApptentiveMetrics.h"
#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATMetric.h"
#import "ATWebClient.h"

#define kATRecordTaskCodingVersion 1

@interface ATRecordTask (Private)
- (BOOL)handleLegacyRecord;
@end

@implementation ATRecordTask {
	ATAPIRequest *request;
}

@synthesize record;

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
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	return YES;
}

- (void)start {
	if ([self handleLegacyRecord]) {
		self.finished = YES;
		return;
	}
	if (!request) {
		request = [self.record requestForSendingRecord];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		request = nil;
		self.inProgress = NO;
	}
}

- (float)percentComplete {
	if (request) {
		return [request percentageComplete];
	} else {
		return 0.0f;
	}
}

- (NSString *)taskName {
	return @"record";
}

- (void)cleanup {
	[record cleanup];
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		[self stop];
		self.finished = YES;
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		ATLogInfo(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
	}
}
@end

@implementation ATRecordTask (Private)
- (BOOL)handleLegacyRecord {
	if ([self.record isKindOfClass:[ATMetric class]]) {
		if ([[ApptentiveMetrics sharedMetrics] upgradeLegacyMetric:(ATMetric *)self.record]) {
			return YES;
		}
	}
	return NO;
}
@end
