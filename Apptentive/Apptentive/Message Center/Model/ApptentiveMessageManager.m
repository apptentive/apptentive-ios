//
//  ApptentiveMessageManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageManager.h"
#import "ApptentiveMessage.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageStore.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"
#import "ApptentiveMessagePayload.h"
#import "ApptentiveMessageGetRequest.h"
#import "ApptentiveClient.h"

static NSString *const MessageStoreFileName = @"messages-v1.archive";


@interface ApptentiveMessageManager ()

@property (strong, nonatomic) ApptentiveRequestOperation *messageOperation;
@property (strong, nonatomic) NSTimer *messageFetchTimer;
@property (strong, nonatomic) NSDictionary *currentCustomData;
@property (readonly, nonatomic) NSMutableDictionary *messageIdentifierIndex;
@property (readonly, nonatomic) ApptentiveMessageStore *messageStore;

@property (readonly, nonatomic) NSString *messageStorePath;
@property (copy, nonatomic) void (^backgroundFetchBlock)(UIBackgroundFetchResult);

@end


@implementation ApptentiveMessageManager

- (instancetype)initWithStoragePath:(NSString *)storagePath client:(ApptentiveClient *)client pollingInterval:(NSTimeInterval)pollingInterval localUserIdentifier:(NSString *)localUserIdentifier {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_client = client;
		_localUserIdentifier = localUserIdentifier;

		_messageIdentifierIndex = [NSMutableDictionary dictionary];
		_messageStore = [NSKeyedUnarchiver unarchiveObjectWithFile:self.messageStorePath] ?: [[ApptentiveMessageStore alloc] init];

		[self updateUnreadCount];

		NSError *error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:self.attachmentDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveAssertTrue(NO, @"Unable to create attachments directory “%@” (%@)", self.attachmentDirectoryPath, error);
			return nil;
		}

		for (ApptentiveMessage *message in _messageStore.messages) {
			ApptentiveAssertNotNil(message.localIdentifier, @"Missing localIdentifier on message in archive");
			if (message.localIdentifier == nil) {
				continue;
			}

			_messageIdentifierIndex[message.localIdentifier] = message;
		}

		// Use setter to initialize timer
		self.pollingInterval = pollingInterval;
	}

	return self;
}

- (void)checkForMessages {
	if (self.messageOperation != nil) {
		return;
	}

	ApptentiveMessageGetRequest *request = [[ApptentiveMessageGetRequest alloc] init];
	request.lastMessageIdentifier = self.messageStore.lastMessageIdentifier;

	self.messageOperation = [self.client requestOperationWithRequest:request delegate:self];

	[self.client.operationQueue addOperation:self.messageOperation];
}

- (void)checkForMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler {
	self.backgroundFetchBlock = completionHandler;

	[self checkForMessages];
}

- (NSInteger)numberOfMessages {
	return self.messages.count;
}

- (NSArray<ApptentiveMessage *> *)messages {
	return self.messageStore.messages;
}

- (NSString *)messageStorePath {
	return [self.storagePath stringByAppendingPathComponent:MessageStoreFileName];
}

- (BOOL)saveMessageStore {
	return [NSKeyedArchiver archiveRootObject:self.messageStore toFile:self.messageStorePath];
}

- (NSString *)attachmentDirectoryPath {
	return [self.storagePath stringByAppendingPathComponent:@"Attachments"];
}

#pragma mark Request Operation Delegate

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	NSArray *messageListJSON = [operation.responseObject valueForKey:@"items"];
	self.messageOperation = nil;

	ApptentiveAssertNotNil(messageListJSON, @"Unexpected response from /messages endpoint");
	if (messageListJSON == nil) {
		return;
	}

	NSMutableArray *mutableMessages = [NSMutableArray arrayWithCapacity:messageListJSON.count];
	NSMutableDictionary *mutableMessageIdentifierIndex = [NSMutableDictionary dictionaryWithCapacity:messageListJSON.count];
	NSMutableArray *addedMessages = [NSMutableArray array];
	NSMutableArray *updatedMessages = [NSMutableArray array];
	NSString *lastDownloadedMessageIdentifier;

	// Correlate messages from server with local messages
	for (NSDictionary *messageJSON in messageListJSON) {
		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithJSON:messageJSON];

		if (message) {
			ApptentiveMessage *previousVersion = self.messageIdentifierIndex[message.localIdentifier];
			BOOL sentByLocalUser = [message.sender.identifier isEqualToString:self.localUserIdentifier];


			if (previousVersion != nil) {
				ApptentiveMessageState previousState = previousVersion.state;

				// Update with server identifier and date
				message = [previousVersion mergedWith:message];

				if (sentByLocalUser) {
					message.state = ApptentiveMessageStateSent;
				}

				if (previousState != message.state) {
					[updatedMessages addObject:message];
				}
			} else {
				[addedMessages addObject:message];

				if (!sentByLocalUser) {
					message.state = ApptentiveMessageStateUnread;
				} // else state defaults to sent
			}

			[mutableMessages addObject:message];
			[mutableMessageIdentifierIndex setObject:message forKey:message.localIdentifier];

			lastDownloadedMessageIdentifier = message.identifier;
		}
	}

	if (addedMessages.count + updatedMessages.count > 0) {
		// Add local messages that aren't yet on server's list
		for (ApptentiveMessage *message in self.messages) {
			ApptentiveMessage *newVersion = mutableMessageIdentifierIndex[message.localIdentifier];

			if (newVersion == nil) {
				[mutableMessages addObject:message];
				[mutableMessageIdentifierIndex setObject:message forKey:message.localIdentifier];
			}
		}

		// Sort by sent date
		[mutableMessages sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sentDate" ascending:YES]]];

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.delegate messageManagerWillBeginUpdates:self];

			[self.messageStore.messages removeAllObjects];
			[self.messageStore.messages addObjectsFromArray:mutableMessages];
			_messageIdentifierIndex = mutableMessageIdentifierIndex;

			for (ApptentiveMessage *newMessage in addedMessages) {
				[self.delegate messageManager:self didInsertMessage:newMessage atIndex:[self.messages indexOfObject:newMessage]];
			}

			for (ApptentiveMessage *updatedMessage in updatedMessages) {
				[self.delegate messageManager:self didUpdateMessage:updatedMessage atIndex:[self.messages indexOfObject:updatedMessage]];
			}

			[self.delegate messageManagerDidEndUpdates:self];
		});

		self.messageStore.lastMessageIdentifier = lastDownloadedMessageIdentifier;
		[self saveMessageStore];

		[self messageFetchCompleted:YES];
		[self updateUnreadCount];
	} else {
		[self messageFetchCompleted:NO];
	}
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	ApptentiveLogError(@"%@ %@ failed with error: %@. Not retrying.", operation.URLRequest.HTTPMethod, operation.URLRequest.URL.absoluteString, error);

	self.messageOperation = nil;
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error {
	if (error) {
		ApptentiveLogError(@"%@ %@ failed with error: %@", operation.URLRequest.HTTPMethod, operation.URLRequest.URL.absoluteString, error);
	}

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.", operation.URLRequest.HTTPMethod, operation.URLRequest.URL.absoluteString, self.client.backoffDelay);
}

#pragma mark - Polling

- (void)stopPolling {
	[self.messageFetchTimer invalidate];
	self.messageFetchTimer = nil;
}

- (void)setPollingInterval:(NSTimeInterval)pollingInterval {
	if (_pollingInterval != pollingInterval) {
		[self stopPolling];

		_pollingInterval = pollingInterval;

		self.messageFetchTimer = [NSTimer timerWithTimeInterval:pollingInterval target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.messageFetchTimer forMode:NSDefaultRunLoopMode];
	}
}

#pragma mark - Sending Messages

- (void)sendMessage:(ApptentiveMessage *)message {
	[self enqueueMessageForSending:message];

	[self appendMessage:message];
}

- (void)enqueueMessageForSending:(ApptentiveMessage *)message {
	NSString *previousLocalIdentifier = message.localIdentifier;
	ApptentiveConversation *conversation = Apptentive.shared.backend.conversationManager.activeConversation;

	ApptentiveMessagePayload *payload = [[ApptentiveMessagePayload alloc] initWithMessage:message];

	[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];

	// Update the message ID index for messages that were previously appended.
	// (i.e. context messages).
	if (previousLocalIdentifier) {
		[self.messageIdentifierIndex removeObjectForKey:previousLocalIdentifier];
		[self.messageIdentifierIndex setObject:message forKey:message.localIdentifier];
	}

	message.state = ApptentiveMessageStateWaiting;
}

- (void)setState:(ApptentiveMessageState)state forMessageWithLocalIdentifier:(NSString *)localIdentifier {
	ApptentiveAssertNotNil(localIdentifier, @"Missing localIdentifier when updating message");
	if (localIdentifier == nil) {
		return;
	}

	ApptentiveMessage *message = self.messageIdentifierIndex[localIdentifier];

	if (message) {
		message.state = state;
		NSInteger index = [self.messages indexOfObject:message];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate messageManagerWillBeginUpdates:self];
			[self.delegate messageManager:self didUpdateMessage:message atIndex:index];
			[self.delegate messageManagerDidEndUpdates:self];
		});
	}
}

- (void)appendMessage:(ApptentiveMessage *)message {
	ApptentiveAssertNotNil(message.localIdentifier, @"Missing localIdentifier when appending message");
	if (message.localIdentifier == nil) {
		return;
	}

	NSInteger index = self.messages.count;
	[self.messageStore.messages addObject:message];
	[self.messageIdentifierIndex setObject:message forKey:message.localIdentifier];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate messageManagerWillBeginUpdates:self];
		[self.delegate messageManager:self didInsertMessage:message atIndex:index];
		[self.delegate messageManagerDidEndUpdates:self];
	});

	[self saveMessageStore];
}

- (void)removeMessage:(ApptentiveMessage *)message {
	NSInteger index = [self.messageStore.messages indexOfObject:message];

	ApptentiveAssertTrue(index != NSNotFound, @"Unable to find message to remove");
	if (index == NSNotFound) {
		return;
	}

	[self.messageStore.messages removeObjectAtIndex:index];

	ApptentiveAssertNotNil(message.localIdentifier, @"Message to remove missing localIdentifier");
	if (message.localIdentifier == nil) {
		return;
	}

	[self.messageIdentifierIndex removeObjectForKey:message.localIdentifier];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate messageManagerWillBeginUpdates:self];
		[self.delegate messageManager:self didDeleteMessage:message atIndex:index];
		[self.delegate messageManagerDidEndUpdates:self];
	});

	[self saveMessageStore];
}

#pragma mark - Private

- (void)updateUnreadCount {
	NSInteger unreadCount = 0;
	for (ApptentiveMessage *message in self.messages) {
		if (message.state == ApptentiveMessageStateUnread) {
			unreadCount++;
		}
	}

	if (_unreadCount != unreadCount) {
		_unreadCount = unreadCount;

		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveMessageCenterUnreadCountChangedNotification object:self userInfo:@{ @"count": @(unreadCount) }];
	}
}

- (void)messageFetchCompleted:(BOOL)success {
	UIBackgroundFetchResult fetchResult = success ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed;

	if (self.backgroundFetchBlock) {
		self.backgroundFetchBlock(fetchResult);

		self.backgroundFetchBlock = nil;
	}
}

@end
