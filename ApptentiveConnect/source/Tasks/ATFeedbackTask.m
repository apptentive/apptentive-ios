//
//  ATFeedbackTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/20/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATFeedbackTask.h"
#import "ATBackend.h"
#import "ATFeedback.h"
#import "ATWebClient.h"

#define kATFeedbackTaskCodingVersion 1

@interface ATFeedbackTask ()

@property (strong, nonatomic) ATAPIRequest *request;

@end

@implementation ATFeedbackTask

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATFeedbackTaskCodingVersion) {
			self.feedback = [coder decodeObjectForKey:@"feedback"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATFeedbackTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.feedback forKey:@"feedback"];
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
	if (!self.request) {
		self.request = [self.feedback requestForSendingRecord];
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
	return @"feedback";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		self.finished = YES;
		[self stop];
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

- (void)cleanup {
	[self.feedback cleanup];
}
@end
