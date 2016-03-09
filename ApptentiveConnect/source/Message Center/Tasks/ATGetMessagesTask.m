//
//  ATGetMessagesTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/12/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATGetMessagesTask.h"

#import "ATBackend.h"
#import "ATCompoundMessage.h"
#import "ATConversationUpdater.h"
#import "ATMessageSender.h"
#import "ATWebClient.h"
#import "ATWebClient+MessageCenter.h"
#import "NSDictionary+ATAdditions.h"
#import "ATConnect_Private.h"

@interface ATGetMessagesTask ()
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end


@implementation ATGetMessagesTask {
	ATAPIRequest *request;
	ATCompoundMessage *lastMessage;
}

- (id)init {
	if ((self = [super init])) {
		NSString *messageID = [ATConnect sharedConnection].backend.currentConversation.lastRetrievedMessageID;
		if (messageID) {
			lastMessage = [ATCompoundMessage findMessageWithID:messageID];
		}
	}
	return self;
}

- (void)dealloc {
	[self stop];
}

- (BOOL)shouldArchive {
	return NO;
}

- (BOOL)canStart {
	if ([ATConnect sharedConnection].webClient == nil) {
		return NO;
	}
	if ([ATConnect sharedConnection].backend.currentConversation.token == nil) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		request = [[ATConnect sharedConnection].webClient requestForRetrievingMessagesSinceMessage:lastMessage];
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
	return @"getmessages";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		UIBackgroundFetchResult fetchResult;

		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
			fetchResult = UIBackgroundFetchResultNewData;
		} else {
			ATLogError(@"Could not process the Get Message Task result!");
			self.failed = YES;
			fetchResult = UIBackgroundFetchResultFailed;
		}
		[self stop];

		[[ATConnect sharedConnection].backend completeMessageFetchWithResult:fetchResult];
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

#pragma mark - Private methods

- (BOOL)processResult:(NSDictionary *)jsonMessages {
	NSManagedObjectContext *context = [[ATConnect sharedConnection].backend managedObjectContext];
	NSString *lastMessageID = nil;

	ATConversation *conversation = [ATConnect sharedConnection].backend.currentConversation;

	do { // once
		if (!jsonMessages) break;
		if (![jsonMessages at_safeObjectForKey:@"items"]) break;

		NSArray *messages = [jsonMessages at_safeObjectForKey:@"items"];
		if (![messages isKindOfClass:[NSArray class]]) break;
		if (messages.count > 0) {
			ATLogDebug(@"Apptentive messages: %@", jsonMessages);
		}

		BOOL success = YES;
		for (NSDictionary *messageJSON in messages) {
			NSString *pendingMessageID = [messageJSON at_safeObjectForKey:@"nonce"];
			NSString *messageID = [messageJSON at_safeObjectForKey:@"id"];
			ATCompoundMessage *message = nil;
			message = [ATCompoundMessage findMessageWithPendingID:pendingMessageID];
			if (!message) {
				message = [ATCompoundMessage findMessageWithID:messageID];
			}
			if (!message) {
				message = (ATCompoundMessage *)[ATCompoundMessage newInstanceWithJSON:messageJSON];
				if (conversation && [conversation.personID isEqualToString:message.sender.apptentiveID]) {
					message.sentByUser = @(YES);
					message.seenByUser = @(YES);
				}
				message.pendingState = @(ATPendingMessageStateConfirmed);
				if (message) {
					lastMessageID = messageID;
				}
			} else {
				lastMessageID = messageID;
				[message updateWithJSON:messageJSON];
			}
			if (!message) {
				success = NO;
				break;
			}
		}
		NSError *error = nil;
		if (![context save:&error]) {
			ATLogError(@"Failed to save messages: %@", error);
			success = NO;
		}
		if (success && lastMessageID) {
			conversation.lastRetrievedMessageID = lastMessageID;
			[[ATConnect sharedConnection].backend saveConversation];
		}
		return YES;
	} while (NO);
	return NO;
}
@end
