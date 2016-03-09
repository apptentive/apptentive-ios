//
//  ATMessageTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/2/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATMessageTask.h"
#import "ATBackend.h"
#import "ATJSONSerialization.h"
#import "ATLog.h"
#import "ATCompoundMessage.h"
#import "ATConversationUpdater.h"
#import "ATConnect_Private.h"
#import "ATWebClient.h"
#import "ATWebClient+MessageCenter.h"

#define kATMessageTaskCodingVersion 2


@interface ATMessageTask ()
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end


@implementation ATMessageTask {
	ATAPIRequest *request;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		int version = [coder decodeIntForKey:@"version"];
		if (version == kATMessageTaskCodingVersion) {
			self.pendingMessageID = [coder decodeObjectForKey:@"pendingMessageID"];
		} else {
			return nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeInt:kATMessageTaskCodingVersion forKey:@"version"];
	[coder encodeObject:self.pendingMessageID forKey:@"pendingMessageID"];
}

- (void)dealloc {
	[self stop];
}

- (BOOL)canStart {
	if ([ATConnect sharedConnection].webClient == nil) {
		ATLogDebug(@"Failed to send message because Apptentive API key is not set!");
		return NO;
	}
	if ([ATConnect sharedConnection].backend.currentConversation.token == nil) {
		return NO;
	}
	if ([[ATConnect sharedConnection].backend isUpdatingPerson]) {
		// Don't send until the person is done being updated.
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		ATCompoundMessage *message = [ATCompoundMessage findMessageWithPendingID:self.pendingMessageID];
		if (message == nil) {
			ATLogError(@"Warning: Message was nil in message task.");
			self.finished = YES;
			return;
		}
		request = [[ATConnect sharedConnection].webClient requestForPostingMessage:message];
		if (request != nil) {
			[[ATConnect sharedConnection].backend messageTaskDidBegin:self];

			request.delegate = self;
			[request start];
			self.inProgress = YES;
		} else {
			self.finished = YES;
		}
		message = nil;
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
	return @"message";
}

- (NSUInteger)hash {
	return self.pendingMessageID.hash;
}

- (BOOL)isEqual:(id)object {
	if (![object isKindOfClass:[self class]]) {
		return NO;
	} else if (self == object) {
		return YES;
	} else {
		return [self.pendingMessageID isEqualToString:((ATMessageTask *)object).pendingMessageID];
	}
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[[ATConnect sharedConnection].backend messageTaskDidFinish:self];

		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			ATLogError(@"Message result is not NSDictionary!");
			self.failed = YES;
		}
		[self stop];
	}
}

- (void)at_APIRequestDidProgress:(ATAPIRequest *)sender {
	[[ATConnect sharedConnection].backend messageTask:self didProgress:self.percentComplete];
}

- (void)at_APIRequestDidFail:(ATAPIRequest *)sender {
	@synchronized(self) {
		[[ATConnect sharedConnection].backend messageTaskDidFail:self];
		self.lastErrorTitle = sender.errorTitle;
		self.lastErrorMessage = sender.errorMessage;

		ATCompoundMessage *message = [ATCompoundMessage findMessageWithPendingID:self.pendingMessageID];
		if (message == nil) {
			ATLogError(@"Warning: Message went away during task.");
			self.finished = YES;
			return;
		}
		[message setErrorOccurred:@(YES)];
		if (sender.errorResponse != nil) {
			NSError *parseError = nil;
			NSObject *errorObject = [ATJSONSerialization JSONObjectWithString:sender.errorResponse error:&parseError];
			if (errorObject != nil && [errorObject isKindOfClass:[NSDictionary class]]) {
				NSDictionary *errorDictionary = (NSDictionary *)errorObject;
				if ([errorDictionary objectForKey:@"errors"]) {
					ATLogInfo(@"ATAPIRequest server error: %@", [errorDictionary objectForKey:@"errors"]);
					[message setErrorMessageJSON:sender.errorResponse];
				}
			} else if (errorObject == nil) {
				ATLogError(@"Error decoding error response: %@", parseError);
			}
			[message setPendingState:@(ATPendingMessageStateError)];
		}
		NSError *error = nil;
		NSManagedObjectContext *context = [[ATConnect sharedConnection].backend managedObjectContext];
		if (![context save:&error]) {
			ATLogError(@"Failed to save message after API failure: %@", error);
		}
		ATLogInfo(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		if (self.failureCount > 2) {
			self.finished = YES;
		} else {
			self.failed = YES;
		}
		[self stop];
		message = nil;
	}
}

#pragma mark - Private methods

- (BOOL)processResult:(NSDictionary *)jsonMessage {
	ATLogDebug(@"getting json result: %@", jsonMessage);
	NSManagedObjectContext *context = [[ATConnect sharedConnection].backend managedObjectContext];

	ATCompoundMessage *message = [ATCompoundMessage findMessageWithPendingID:self.pendingMessageID];
	if (message == nil) {
		ATLogError(@"Warning: Message went away during task.");
		return YES;
	}
	[message updateWithJSON:jsonMessage];
	message.pendingState = [NSNumber numberWithInt:ATPendingMessageStateConfirmed];

	NSError *error = nil;
	if (![context save:&error]) {
		ATLogError(@"Failed to save new message: %@", error);
		message = nil;
		return NO;
	}
	message = nil;
	return YES;
}
@end
