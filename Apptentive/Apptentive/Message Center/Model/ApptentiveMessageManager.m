//
//  ApptentiveMessageManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageManager.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveBackend.h"
#import "ApptentiveClient.h"
#import "ApptentiveMessage.h"
#import "ApptentiveMessageGetRequest.h"
#import "ApptentiveMessagePayload.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveMessageStore.h"
#import "ApptentivePerson.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const MessageStoreFileName = @"messages-v1.archive";

NSString *const ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";
NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";


@interface ApptentiveMessageManager ()

@property (nullable, strong, nonatomic) ApptentiveRequestOperation *messageOperation;
@property (nullable, strong, nonatomic) NSTimer *messageFetchTimer;
@property (strong, nonatomic) NSDictionary *currentCustomData;
@property (readonly, nonatomic) NSMutableDictionary *messageIdentifierIndex;
@property (readonly, nonatomic) ApptentiveMessageStore *messageStore;
@property (readonly, nonatomic) NSInteger unreadCount;

@property (readonly, nonatomic) NSString *messageStorePath;
@property (nullable, copy, nonatomic) void (^backgroundFetchBlock)(UIBackgroundFetchResult);

@end


@implementation ApptentiveMessageManager

- (instancetype)initWithStoragePath:(NSString *)storagePath client:(ApptentiveClient *)client pollingInterval:(NSTimeInterval)pollingInterval conversation:(ApptentiveConversation *)conversation operationQueue:(ApptentiveDispatchQueue *)operationQueue {
	self = [super init];

	if (self) {
		ApptentiveAssertNotNil(storagePath, @"Storage path is nil");
		ApptentiveAssertNotNil(conversation, @"Conversation is nil");

		// TODO: return nil if any of the params are nil

		_conversation = conversation;
		_storagePath = storagePath;
		_client = client;
		_operationQueue = operationQueue;

		_messageIdentifierIndex = [NSMutableDictionary dictionary];
		_messageStore = [NSKeyedUnarchiver unarchiveObjectWithFile:self.messageStorePath] ?: [[ApptentiveMessageStore alloc] init];

		_didSkipProfile = [conversation.userInfo[ATMessageCenterDidSkipProfileKey] boolValue];
		_draftMessage = conversation.userInfo[ATMessageCenterDraftMessageKey];

		for (ApptentiveMessage *message in _messageStore.messages) {
			for (ApptentiveAttachment *attachment in message.attachments) {
				attachment.attachmentDirectoryPath = self.attachmentDirectoryPath;
			}
		}

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

- (void)stop {
	[self stopPolling];
	[self deleteCachedAttachments];
}

- (void)checkForMessages {
	if (self.messageOperation != nil || self.conversationIdentifier == nil) {
		return;
	}

	ApptentiveRequestOperationCallback *callback = [ApptentiveRequestOperationCallback new];
	callback.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
	  self.messageOperation = nil;
	  [self processMessageOperationResponse:operation];
	};
	callback.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
	  self.messageOperation = nil;
	};

	ApptentiveMessageGetRequest *request = [[ApptentiveMessageGetRequest alloc] initWithConversationIdentifier:self.conversationIdentifier];
	request.lastMessageIdentifier = self.messageStore.lastMessageIdentifier;

	self.messageOperation = [self.client requestOperationWithRequest:request token:self.conversation.token delegate:callback];

	[self.client.networkQueue addOperation:self.messageOperation];
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
	return [[self class] attachmentDirectoryPathForConversationDirectory:self.storagePath];
}

+ (NSString *)attachmentDirectoryPathForConversationDirectory:(NSString *)conversationDirectory {
	NSString *result = [conversationDirectory stringByAppendingPathComponent:@"Attachments"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
		NSError *error;

		if (![[NSFileManager defaultManager] createDirectoryAtPath:result withIntermediateDirectories:YES attributes:nil error:&error]) {
			ApptentiveLogError(@"Unable to create attachments directory (%@): %@", result, error);
			return nil;
		}
	}

	return result;
}

- (void)setDidSkipProfile:(BOOL)didSkipProfile {
	_didSkipProfile = didSkipProfile;

	[self.operationQueue dispatchAsync:^{
		[self.conversation setUserInfo:@(didSkipProfile) forKey:ATMessageCenterDidSkipProfileKey];
	}];
}

- (void)setDraftMessage:(NSString *)draftMessage {
	_draftMessage = draftMessage;

	[self.operationQueue dispatchAsync:^{
		if (draftMessage == nil) {
			[self.conversation removeUserInfoForKey:ATMessageCenterDraftMessageKey];
		} else {
			[self.conversation setUserInfo:draftMessage forKey:ATMessageCenterDraftMessageKey];
		}
	}];
}

#pragma mark Request Operation Delegate

- (void)processMessageOperationResponse:(ApptentiveRequestOperation *)operation {
	NSArray *messageListJSON = [operation.responseObject valueForKey:@"messages"];

	if (messageListJSON == nil) {
		ApptentiveLogError(@"Unexpected response from /messages endpoint");
		return;
	}

	NSMutableArray *mutableMessages = [NSMutableArray arrayWithCapacity:messageListJSON.count];
	NSMutableDictionary *mutableMessageIdentifierIndex = [NSMutableDictionary dictionaryWithCapacity:messageListJSON.count];
	NSMutableArray *addedMessages = [NSMutableArray array];
	NSMutableArray *updatedMessages = [NSMutableArray array];
	NSString *lastDownloadedMessageIdentifier = self.messageStore.lastMessageIdentifier;

	// Correlate messages from server with local messages
	for (NSDictionary *messageJSON in messageListJSON) {
		ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithJSON:messageJSON];

		if (message) {
			ApptentiveMessage *previousVersion = [self.messageIdentifierIndex[message.localIdentifier] copy];

			if (previousVersion != nil) {
				ApptentiveMessageState previousState = previousVersion.state;

				// Update with server identifier and date
				message = [previousVersion mergedWith:message];

				if (previousState != message.state) {
					ApptentiveArrayAddObject(updatedMessages, message);
				}
			} else {
				ApptentiveArrayAddObject(addedMessages, message);
			}

			ApptentiveArrayAddObject(mutableMessages, message);
			ApptentiveDictionarySetKeyValue(mutableMessageIdentifierIndex, message.localIdentifier, message);

			lastDownloadedMessageIdentifier = message.identifier;
		} else {
			ApptentiveLogError(@"Unable to create message from JSON: %@", messageJSON);
		}
	}

	ApptentiveAssertOperationQueue(Apptentive.shared.backend.operationQueue);

	BOOL needsSave = NO;

	if (self.messageStore.lastMessageIdentifier != lastDownloadedMessageIdentifier) {
		self.messageStore.lastMessageIdentifier = lastDownloadedMessageIdentifier;
		needsSave = YES;
	}

	if (addedMessages.count + updatedMessages.count > 0) {
		// Add local messages that aren't yet on server's list
		for (ApptentiveMessage *message in self.messages) {
			ApptentiveMessage *newVersion = mutableMessageIdentifierIndex[message.localIdentifier];

			if (newVersion == nil) {
				ApptentiveArrayAddObject(mutableMessages, message);
				ApptentiveDictionarySetKeyValue(mutableMessageIdentifierIndex, message.localIdentifier, message);
			}
		}

		// Sort by sent date
		[mutableMessages sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sentDate" ascending:YES]]];

		// But make sure any context message always sorts to end of list
		if (self.messages.lastObject.automated) {
			NSString *lastContextMessageIdentifier = self.messages.lastObject.localIdentifier;
			ApptentiveAssertNotNil(lastContextMessageIdentifier, @"Last context message identifier is nil");
			ApptentiveMessage *lastContextMessage = lastContextMessageIdentifier ? mutableMessageIdentifierIndex[lastContextMessageIdentifier] : nil;
			ApptentiveAssertNotNil(lastContextMessage, @"Can't find last context message with identifier: %@", lastContextMessageIdentifier);
			if (lastContextMessage != nil) {
				[mutableMessages removeObject:lastContextMessage];
				[mutableMessages addObject:lastContextMessage];
			}
		}

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

		needsSave = YES;

		[self messageFetchCompleted:YES];
		[self updateUnreadCount];
	} else {
		[self messageFetchCompleted:NO];
	}

	if (needsSave) {
		[self saveMessageStore];
	}
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
	[self.operationQueue dispatchAsync:^{
	  message.sender = [[ApptentiveMessageSender alloc] initWithName:nil identifier:self.localUserIdentifier profilePhotoURL:nil];

	  [self enqueueMessageForSending:message];

	  [self appendMessage:message];
	}];
}

- (void)enqueueMessageForSendingOnBackgroundQueue:(ApptentiveMessage *)message {
	[self.operationQueue dispatchAsync:^{
	  [self enqueueMessageForSending:message];
	}];
}

- (void)enqueueMessageForSending:(ApptentiveMessage *)message {
	ApptentiveAssertOperationQueue(self.operationQueue);

	NSString *previousLocalIdentifier = message.localIdentifier;
	ApptentiveConversation *conversation = Apptentive.shared.backend.conversationManager.activeConversation;

	ApptentiveMessagePayload *payload = [[ApptentiveMessagePayload alloc] initWithMessage:message];

	[ApptentiveSerialRequest enqueuePayload:payload forConversation:conversation usingAuthToken:conversation.token inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];

	// Update the message ID index for messages that were previously appended.
	// (i.e. context messages).
	if (previousLocalIdentifier) {
		[self.messageIdentifierIndex removeObjectForKey:previousLocalIdentifier];
		ApptentiveDictionarySetKeyValue(self.messageIdentifierIndex, message.localIdentifier, message);
	}

	message.state = ApptentiveMessageStateWaiting;
}

#pragma mark - Client message delelgate

- (void)payloadSender:(ApptentivePayloadSender *)sender setState:(ApptentiveMessageState)state forMessageWithLocalIdentifier:(NSString *)localIdentifier {
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

- (void)payloadSenderProgressDidChange:(ApptentivePayloadSender *)sender toValue:(double)value {
	[self.delegate messageManager:self messageSendProgressDidUpdate:value];
}

- (void)appendMessage:(ApptentiveMessage *)message {
	ApptentiveAssertNotNil(message.localIdentifier, @"Missing localIdentifier when appending message");
	if (message.localIdentifier == nil) {
		return;
	}

	NSInteger index = self.messages.count;
	ApptentiveArrayAddObject(self.messageStore.messages, message);
	ApptentiveDictionarySetKeyValue(self.messageIdentifierIndex, message.localIdentifier, message);

	if (self.delegate) {
		dispatch_async(dispatch_get_main_queue(), ^{
		  [self.delegate messageManagerWillBeginUpdates:self];
		  [self.delegate messageManager:self didInsertMessage:message atIndex:index];
		  [self.delegate messageManagerDidEndUpdates:self];
		});
	}

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

- (void)updateUnreadCount {
	NSInteger unreadCount = 0;
	for (ApptentiveMessage *message in self.messages) {
		if (message.state == ApptentiveMessageStateUnread) {
			unreadCount++;
		}
	}

	if (_unreadCount != unreadCount) {
		_unreadCount = unreadCount;

		dispatch_async(dispatch_get_main_queue(), ^{
		  Apptentive.shared.backend.unreadMessageCount = unreadCount;
		  [[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveMessageCenterUnreadCountChangedNotification object:self userInfo:@{ @"count": @(unreadCount) }];
		});
	}
}

#pragma mark - Attachments

- (void)deleteCachedAttachments {
	for (ApptentiveMessage *message in self.messageStore.messages) {
		for (ApptentiveAttachment *attachment in message.attachments) {
			[attachment deleteLocalContent];
		}
	}

	[self saveMessageStore];
}

#pragma mark - Private

- (void)messageFetchCompleted:(BOOL)success {
	UIBackgroundFetchResult fetchResult = success ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed;

	if (self.backgroundFetchBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
		  self.backgroundFetchBlock(fetchResult);

		  self.backgroundFetchBlock = nil;
		});
	}
}

#pragma mark -
#pragma mark Properties

- (NSString *)conversationIdentifier {
	return self.conversation.identifier;
}

- (NSString *)localUserIdentifier {
	return self.conversation.person.identifier;
}

@end

NS_ASSUME_NONNULL_END
