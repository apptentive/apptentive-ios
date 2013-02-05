//
//  ATMessageTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessageTask.h"
#import "ATBackend.h"
#import "ATLog.h"
#import "ATMessage.h"
#import "ATActivityFeedUpdater.h"
#import "ATTextMessage.h"
#import "ATWebClient.h"
#import "ATWebClient+MessageCenter.h"

#define kATMessageTaskCodingVersion 1

@interface ATMessageTask (Private)
- (void)setup;
- (void)teardown;
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end

@implementation ATMessageTask
@synthesize message;

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMessageTaskCodingVersion) {
			self.message = [coder decodeObjectForKey:@"message"];
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATMessageTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.message forKey:@"message"];
}

- (void)dealloc {
	[self teardown];
	[message release], message = nil;
	[super dealloc];
}

- (BOOL)canStart {
#if APPTENTIVE_DEMO
	return YES;
#endif
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	if (![ATActivityFeedUpdater activityFeedExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
#if APPTENTIVE_DEMO
	[self processResult:@{@"id":@"fobar132", @"sender_id":@"demouserid"}];
	self.inProgress = NO;
	self.finished = YES;
#else
	if (!request) {
		request = [[[ATWebClient sharedClient] requestForPostingMessage:self.message] retain];
		if (request != nil) {
			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
	}
#endif
}

- (void)stop {
	if (request) {
		request.delegate = nil;
		[request cancel];
		[request release], request = nil;
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
	return @"message";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		
		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			ATLogError(@"Message result is not NSDictionary!");
			self.failed = YES;
		}
		[self stop];
		[self release];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	// pass
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		[self retain];
		self.failed = YES;
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;
		ATLogError(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
		[self release];
	}
}
@end

@implementation ATMessageTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}

- (BOOL)processResult:(NSDictionary *)jsonMessage {
	ATLogInfo(@"getting json result: %@", jsonMessage);
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	ATTextMessage *textMessage = [ATTextMessage findMessageWithPendingID:message.pendingMessageID];
	[textMessage updateWithJSON:jsonMessage];
	textMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateConfirmed];
	
	NSError *error = nil;
	if (![context save:&error]) {
		ATLogError(@"Failed to save new message: %@", error);
		return NO;
	}
	return YES;
}
@end
