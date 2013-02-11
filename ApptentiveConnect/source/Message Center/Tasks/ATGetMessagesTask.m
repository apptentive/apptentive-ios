//
//  ATGetMessagesTask.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/12/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ATGetMessagesTask.h"

#import "ATBackend.h"
#import "ATMessage.h"
#import "ATActivityFeedUpdater.h"
#import "ATTextMessage.h"
#import "ATWebClient.h"
#import "ATWebClient+MessageCenter.h"
#import "NSDictionary+ATAdditions.h"

static NSString *const ATMessagesLastRetrievedMessageIDPreferenceKey = @"ATMessagesLastRetrievedMessagIDPreferenceKey";


@interface ATGetMessagesTask (Private)
- (void)setup;
- (void)teardown;
- (BOOL)processResult:(NSDictionary *)jsonMessage;
@end

@implementation ATGetMessagesTask

- (id)init {
	if ((self = [super init])) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *messageID = [defaults objectForKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
		if (messageID) {
			lastMessage = [[ATMessage findMessageWithID:messageID] retain];
		}
	}
	return self;
}

- (void)dealloc {
	[self teardown];
	[lastMessage release], lastMessage = nil;
	[super dealloc];
}

- (BOOL)shouldArchive {
	return NO;
}

- (BOOL)canStart {
	if ([[ATBackend sharedBackend] apiKey] == nil) {
		return NO;
	}
	if (![ATActivityFeedUpdater activityFeedExists]) {
		return NO;
	}
	return YES;
}

- (void)start {
	if (!request) {
		request = [[[ATWebClient sharedClient] requestForRetrievingMessagesSinceMessage:lastMessage] retain];
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
	return @"getmessages";
}

#pragma mark ATAPIRequestDelegate
- (void)at_APIRequestDidFinish:(ATAPIRequest *)sender result:(NSObject *)result {
	@synchronized(self) {
		[self retain];
		
		if ([result isKindOfClass:[NSDictionary class]] && [self processResult:(NSDictionary *)result]) {
			self.finished = YES;
		} else {
			NSLog(@"Messages result is not NSDictionary!");
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
		NSLog(@"ATAPIRequest failed: %@, %@", sender.errorTitle, sender.errorMessage);
		[self stop];
		[self release];
	}
}
@end

@implementation ATGetMessagesTask (Private)
- (void)setup {
	
}

- (void)teardown {
	[self stop];
}

- (BOOL)processResult:(NSDictionary *)jsonMessages {
	NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
	NSString *lastMessageID = nil;
	
	do { // once
		if (!jsonMessages) break;
		if (![jsonMessages at_safeObjectForKey:@"items"]) break;
		
		NSArray *messages = [jsonMessages at_safeObjectForKey:@"items"];
		if (![messages isKindOfClass:[NSArray class]]) break;
		
		BOOL success = YES;
		for (NSDictionary *messageJSON in messages) {
			NSString *messageID = [messageJSON at_safeObjectForKey:@"id"];
			ATMessage *message = [ATMessage findMessageWithID:messageID];
			if (!message) {
				NSString *type = [messageJSON at_safeObjectForKey:@"type"];
				if ([type isEqualToString:@"TextMessage"]) {
					message = [[ATTextMessage newInstanceWithJSON:messageJSON] autorelease];
				} else if ([type isEqualToString:@"FileMessage"]) {
#warning Add file message here.
				}
				message.pendingState = @(ATPendingMessageStateConfirmed);
				if (message) {
					lastMessageID = messageID;
				}
			} else {
				lastMessageID = messageID;
			}
			if (!message) {
				success = NO;
				break;
			}
		}
		NSError *error = nil;
		if (![context save:&error]) {
			NSLog(@"Failed to save messages: %@", error);
			success = NO;
		}
		if (success && lastMessageID) {
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
			[defaults setObject:lastMessageID forKey:ATMessagesLastRetrievedMessageIDPreferenceKey];
			[defaults synchronize];
		}
		return YES;
	} while (NO);
	return NO;
}
@end
