//
//  ApptentiveMessageManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageManager.h"
#import "ApptentiveMessage.h"
#import "ApptentiveNetworkQueue.h"
#import "ApptentiveSerialRequest+Record.h"

#import "Apptentive_Private.h"
#import "ApptentiveMessageSender.h"
#import "ApptentiveBackend.h"
#import "ApptentiveSession.h"
#import "ApptentivePerson.h"
#import "ApptentiveFileAttachment.h"

@interface ApptentiveMessageManager ()

@property (strong, nonatomic) ApptentiveRequestOperation *messageOperation;
@property (strong, nonatomic) NSTimer *messageFetchTimer;
@property (strong, nonatomic) NSDictionary *currentCustomData;

@end

@implementation ApptentiveMessageManager

- (instancetype)initWithStoragePath:(NSString *)storagePath networkQueue:(ApptentiveNetworkQueue *)networkQueue pollingInterval:(NSTimeInterval)pollingInterval {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_networkQueue = networkQueue;

		// TODO: Load previous messages from disk

		// Use setter to initialize timer
		self.pollingInterval = pollingInterval;
	}

	return self;
}

- (void)checkForMessages {
	if (self.messageOperation != nil) {
		return;
	}

	// TODO: limit request to un-downloaded messages
	self.messageOperation = [[ApptentiveRequestOperation alloc] initWithPath:@"conversation" method:@"GET" payload:nil delegate:self dataSource:self.networkQueue];

	[self.networkQueue addOperation:self.messageOperation];
}

#pragma mark Request Operation Delegate

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	NSArray *messageListJSON = [operation.responseObject valueForKey:@"items"];
	self.messageOperation = nil;

	if (messageListJSON == nil) {
		ApptentiveLogError(@"Unexpected response from messages request");
		return;
	}

	NSMutableArray *mutableMessages = [NSMutableArray arrayWithCapacity:messageListJSON.count];
	for (NSDictionary *messageJSON in messageListJSON) {
		// TODO: Assert that messageJSON is, in fact, a dictionary
		ApptentiveMessage *message = [ApptentiveMessage messageWithJSON:messageJSON];

		if (message) {
			if ([message.sender.apptentiveID isEqualToString:Apptentive.shared.backend.session.person.identifier]) {
				message.seenByUser = @YES;
				message.sentByUser = @YES;
			}

			[mutableMessages addObject:message];
		}
	}
	_messages = [mutableMessages copy];

	// Update unread count
	NSInteger unreadCount = 0;
	for (ApptentiveMessage *message in self.messages) {
		if (![message.seenByUser boolValue]) {
			unreadCount ++;
		}
	}

	if (_unreadCount != unreadCount) {
		_unreadCount = unreadCount;

		[[NSNotificationCenter defaultCenter] postNotificationName:ApptentiveMessageCenterUnreadCountChangedNotification object:self userInfo:@{ @"count": @(unreadCount) }];
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

		self.messageFetchTimer = [NSTimer timerWithTimeInterval:pollingInterval	target:self selector:@selector(checkForMessages) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:self.messageFetchTimer forMode:NSDefaultRunLoopMode];
	}
}

#pragma mark - Sending Messages

- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body {
	ApptentiveMessage *message = [ApptentiveMessage newInstanceWithBody:body attachments:nil];
	message.hidden = @NO;
	message.title = title;
	message.pendingState = @(ATPendingMessageStateComposing);
	message.sentByUser = @YES;
	message.automated = @YES;
	NSError *error = nil;
	if (![Apptentive.shared.backend.managedObjectContext save:&error]) {
		ApptentiveLogError(@"Unable to send automated message with title: %@, body: %@, error: %@", title, body, error);
		message = nil;
	}

	return message;
}

- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message {
	message.pendingState = @(ATPendingMessageStateSending);

	return [self sendMessage:message];
}

- (BOOL)sendTextMessageWithBody:(NSString *)body {
	return [self sendTextMessageWithBody:body hiddenOnClient:NO];
}

- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden {
	return [self sendTextMessage:[self createTextMessageWithBody:body hiddenOnClient:hidden]];
}

- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden {
	ApptentiveMessage *message = [ApptentiveMessage newInstanceWithBody:body attachments:nil];
	message.sentByUser = @YES;
	message.seenByUser = @YES;
	message.hidden = @(hidden);

	if (!hidden) {
		[self attachCustomDataToMessage:message];
	}

	return message;
}

- (BOOL)sendTextMessage:(ApptentiveMessage *)message {
	message.pendingState = @(ATPendingMessageStateSending);

	return [self sendMessage:message];
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image {
	return [self sendImageMessageWithImage:image hiddenOnClient:NO];
}

- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden {
	NSData *imageData = UIImageJPEGRepresentation(image, 0.95);
	NSString *mimeType = @"image/jpeg";
	return [self sendFileMessageWithFileData:imageData andMimeType:mimeType hiddenOnClient:hidden];
}


- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType {
	return [self sendFileMessageWithFileData:fileData andMimeType:mimeType hiddenOnClient:NO];
}

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden {
	ApptentiveFileAttachment *fileAttachment = [ApptentiveFileAttachment newInstanceWithFileData:fileData MIMEType:mimeType name:nil];
	return [self sendCompoundMessageWithText:nil attachments:@[fileAttachment] hiddenOnClient:hidden];
}

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden {
	ApptentiveMessage *compoundMessage = [ApptentiveMessage newInstanceWithBody:text attachments:attachments];
	compoundMessage.pendingState = @(ATPendingMessageStateSending);
	compoundMessage.sentByUser = @YES;
	compoundMessage.hidden = @(hidden);

	return [self sendMessage:compoundMessage];
}

- (BOOL)sendMessage:(ApptentiveMessage *)message {
	NSAssert([NSThread isMainThread], @"-sendMessage: should only be called on main thread");

	ApptentiveMessageSender *sender = [ApptentiveMessageSender findSenderWithID:Apptentive.shared.backend.session.person.identifier inContext:Apptentive.shared.backend.managedObjectContext];
	if (sender) {
		message.sender = sender;
	}

	NSError *error;
	if (![Apptentive.shared.backend.managedObjectContext save:&error]) {
		ApptentiveLogError(@"Error (%@) saving message: %@", error, message);
		return NO;
	}

	[ApptentiveSerialRequest enqueueMessage:message inContext:Apptentive.shared.backend.managedObjectContext];

	[Apptentive.shared.backend processQueuedRecords];

	return YES;
}

- (void)attachCustomDataToMessage:(ApptentiveMessage *)message {
	if (self.currentCustomData) {
		[message addCustomDataFromDictionary:self.currentCustomData];
		// Only attach custom data to the first message.
		self.currentCustomData = nil;
	}
}

@end
