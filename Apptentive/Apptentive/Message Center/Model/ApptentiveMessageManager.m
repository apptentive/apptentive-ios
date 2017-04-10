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
#import "ApptentiveNetworkQueue.h"
#import "ApptentiveSerialRequest+Record.h"
#import "ApptentiveMessageStore.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend.h"

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

- (instancetype)initWithStoragePath:(NSString *)storagePath networkQueue:(ApptentiveNetworkQueue *)networkQueue pollingInterval:(NSTimeInterval)pollingInterval localUserIdentifier:(NSString *)localUserIdentifier {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_networkQueue = networkQueue;
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
#warning ApptentiveSafeCollections
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

	NSString *path = @"conversation";
	if (self.messageStore.lastMessageIdentifier != nil) {
		path = [path stringByAppendingFormat:@"?after_id=%@", self.messageStore.lastMessageIdentifier];
	}

	self.messageOperation = [[ApptentiveRequestOperation alloc] initWithPath:path method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.messageOperation];
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

	if (messageListJSON == nil) {
#warning use assert
		ApptentiveLogError(@"Unexpected response from /messages request");
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
	ApptentiveLogError(@"%@ %@ failed with error: %@. Not retrying.", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);

	self.messageOperation = nil;
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error {
	if (error) {
		ApptentiveLogError(@"%@ %@ failed with error: %@", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);
	}

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.", operation.request.HTTPMethod, operation.request.URL.absoluteString, self.networkQueue.backoffDelay);
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

	[ApptentiveSerialRequest enqueueMessage:message conversation:Apptentive.shared.backend.conversationManager.activeConversation inContext:Apptentive.shared.backend.managedObjectContext];

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
	[self.messageStore.messages removeObjectAtIndex:index];

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
			unreadCount ++;
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
