//
//  ATRecordRequestTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/10/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveRecordRequestTask.h"
#import "ApptentiveData.h"
#import "ApptentiveWebClient.h"
#import "Apptentive_Private.h"
#import "ApptentiveConversationUpdater.h"

#define kATRecordRequestTaskCodingVersion 1


@interface ApptentiveRecordRequestTask ()

@property (strong, nonatomic) ApptentiveAPIRequest *request;

@end


@implementation ApptentiveRecordRequestTask

+ (void)initialize {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATRecordRequestTask"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATRecordRequestTaskCodingVersion) {
			NSURL *providerURI = [coder decodeObjectForKey:@"managedObjectURIRepresentation"];
			NSManagedObject *obj = [ApptentiveData findEntityWithURI:providerURI];
			if (obj == nil) {
				ApptentiveLogError(@"Unarchived task can't be found in CoreData");
				self.finished = YES;
			} else if ([obj conformsToProtocol:@protocol(ATRequestTaskProvider)]) {
				_taskProvider = (NSObject<ATRequestTaskProvider> *)obj;
			} else {
				ApptentiveLogError(@"Unarchived task doesn't conform to ATRequestTaskProvider protocol.");
				goto fail;
			}
		} else {
			goto fail;
		}
	}
	return self;
fail:
	;
	return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATRecordRequestTaskCodingVersion forKey:@"version"];
	NSURL *URL = [self.taskProvider managedObjectURIRepresentationForTask:self];
	[coder encodeObject:URL forKey:@"managedObjectURIRepresentation"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([Apptentive sharedConnection].webClient == nil) {
		return NO;
	}
	if (![ApptentiveConversationUpdater conversationExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!self.request) {
		self.request = [self.taskProvider requestForTask:self];
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
	return @"request";
}

- (void)cleanup {
	[self.taskProvider cleanupAfterTask:self];
}

#pragma mark ApptentiveAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ApptentiveAPIRequest *)sender result:(id)result {
	@synchronized(self) {
		ATRecordRequestTaskResult taskResult = [self.taskProvider taskResultForTask:self withRequest:sender withResult:result];
		switch (taskResult) {
			case ATRecordRequestTaskFailedResult:
				self.failed = YES;
				break;
			case ATRecordRequestTaskFinishedResult:
				self.finished = YES;
				break;
		}
		[self stop];
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
		ApptentiveLogInfo(@"ApptentiveAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
	}
}
@end
