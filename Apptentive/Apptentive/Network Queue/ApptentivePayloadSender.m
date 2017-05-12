//
//  ApptentivePayloadSender.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/25/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayloadSender.h"
#import "ApptentiveClient.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveMessageSendRequest.h"


@interface ApptentivePayloadSender ()

@property (strong, nonatomic) NSMutableDictionary *activeTaskProgress;
@property (assign, atomic) BOOL isResuming;

@end


@implementation ApptentivePayloadSender

- (instancetype)initWithBaseURL:(NSURL *)baseURL apptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	self = [super initWithBaseURL:baseURL apptentiveKey:apptentiveKey apptentiveSignature:apptentiveSignature];

	if (self) {
		_managedObjectContext = managedObjectContext;

		self.operationQueue.maxConcurrentOperationCount = 1;

		_activeTaskProgress = [[NSMutableDictionary alloc] init];
	}

	return self;
}

#pragma mark - Cancelling network operations

- (void)cancelNetworkOperations {
	[self.operationQueue cancelAllOperations];

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Clearing isResuming Flag");
	self.isResuming = NO;
}

#pragma mark - Creating network operations from queued payloads

- (void)createOperationsForQueuedRequestsInContext:(NSManagedObjectContext *)context {
	if (self.isResuming) {
		ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Already creating operations for queued payloads. Skipping.");
		return;
	}

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Setting isResuming Flag");
	self.isResuming = YES;

	NSBlockOperation *resumeBlock = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[moc setParentContext:context];

		__block NSArray *queuedRequests;
		[moc performBlockAndWait:^{
			NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
			fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES] ];
			fetchRequest.predicate = [NSPredicate predicateWithFormat:@"conversationIdentifier != nil"]; // make sure we don't include "anonymous" conversation here

			NSError *error;
			queuedRequests = [moc executeFetchRequest:fetchRequest error:&error];

			if (queuedRequests == nil) {
				ApptentiveLogError(ApptentiveLogTagPayload, @"Unable to fetch waiting network payloads.");
			}

			ApptentiveLogDebug(ApptentiveLogTagPayload, @"Adding %d record operations for queued payloads", queuedRequests.count);

			// Add an operation for every record in the queue
			for (ApptentiveSerialRequest *requestInfo in [queuedRequests copy]) {
				id<ApptentiveRequest> request;

				if ([requestInfo.path isEqualToString:@"messages"]) {
					ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Adding attachments to message payload");
					request = [[ApptentiveMessageSendRequest alloc] initWithRequest:requestInfo];
				} else {
					request = requestInfo;
				}

				ApptentiveRequestOperation *operation = [self requestOperationWithRequest:request authToken:requestInfo.authToken delegate:self];
				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Adding operation for %@ %@", operation.URLRequest.HTTPMethod, operation.URLRequest.URL.absoluteString);

				operation.request = request;

				[self.operationQueue addOperation:operation];
			}
		}];

		if (queuedRequests.count) {
			// Save the context after all enqueued records have been sent
			NSBlockOperation *saveBlock = [NSBlockOperation blockOperationWithBlock:^{
				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Saving Private Managed Object Context (with completed payloads deleted)");
				[moc performBlockAndWait:^{
					NSError *saveError;
					if (![moc save:&saveError]) {
						ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
					}
				}];

				ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Saving Parent Managed Object Context (with completed payloads deleted)");
				dispatch_async(dispatch_get_main_queue(), ^{
					NSError *parentSaveError;
					if (![moc.parentContext save:&parentSaveError]) {
						ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
					}

					if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
						[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
						self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
					}
				});
			}];

			[self.operationQueue addOperation:saveBlock];
		}

		ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Clearing isResuming Flag");
		self.isResuming = NO;
	}];

	[self.operationQueue addOperation:resumeBlock];
}

#pragma mark - Message send progress

#pragma mark URL sesison delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
	if (self.activeTaskProgress[@(task.taskIdentifier)]) {
		self.activeTaskProgress[@(task.taskIdentifier)] = [NSNumber numberWithDouble:(double)totalBytesSent / (double)totalBytesExpectedToSend];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateProgress];
		});
	}
}

- (void)updateProgress {
	float messageSendProgress = [[self.activeTaskProgress.allValues valueForKeyPath:@"@avg.self"] floatValue];

	if (self.activeTaskProgress.count > 0 && messageSendProgress < 0.05) {
		messageSendProgress = 0.05;
	}

	if (_messageSendProgress != messageSendProgress) {
		_messageSendProgress = messageSendProgress;

		dispatch_async(dispatch_get_main_queue(), ^{
			[self.messageDelegate payloadSenderProgressDidChange:self];
		});
	}
}

- (void)addActiveOperation:(ApptentiveRequestOperation *)operation {
	if ([operation.request isKindOfClass:[ApptentiveMessageSendRequest class]]) {
		[self.activeTaskProgress setObject:@0 forKey:@(operation.task.taskIdentifier)];
		[self updateProgress];
	}
}

- (void)removeActiveOperation:(ApptentiveRequestOperation *)operation {
	if ([operation.request isKindOfClass:[ApptentiveMessageSendRequest class]]) {
		[self.activeTaskProgress removeObjectForKey:@(operation.task.taskIdentifier)];
		[self updateProgress];
	}
}

- (void)updateMessageStatusForOperation:(ApptentiveRequestOperation *)operation {
	for (NSOperation *operation in self.operationQueue.operations) {
		if ([operation isKindOfClass:[ApptentiveRequestOperation class]] && [((ApptentiveRequestOperation *)operation).request isKindOfClass:[ApptentiveMessageSendRequest class]]) {
			ApptentiveRequestOperation *messageOperation = (ApptentiveRequestOperation *)operation;
			ApptentiveMessageSendRequest *messageSendRequest = messageOperation.request;
			ApptentiveMessageState state;

			if (self.status == ApptentiveQueueStatusError) {
				state = ApptentiveMessageStateFailedToSend;
			} else if (messageOperation != operation) {
				state = ApptentiveMessageStateSending;
			} else {
				state = ApptentiveMessageStateSent;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.messageDelegate payloadSender:self setState:state forMessageWithLocalIdentifier:messageSendRequest.messageIdentifier];
			});
		}
	}
}

#pragma mark Request Operation Delegate

- (void)requestOperationDidStart:(ApptentiveRequestOperation *)operation {
	[self addActiveOperation:operation];
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error {
	if (error) {
		_status = ApptentiveQueueStatusError;

		[self updateMessageStatusForOperation:operation];
	}

	[self removeActiveOperation:operation];
}

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	_status = ApptentiveQueueStatusGroovy;

	if ([operation.request isKindOfClass:[ApptentiveSerialRequest class]] || [operation.request isKindOfClass:[ApptentiveMessageSendRequest class]]) {
		[self deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)operation.request];
	}

	[self updateMessageStatusForOperation:operation];

	[self removeActiveOperation:operation];
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	_status = ApptentiveQueueStatusError;

	if ([operation.request isKindOfClass:[ApptentiveSerialRequest class]] || [operation.request isKindOfClass:[ApptentiveMessageSendRequest class]]) {
		[self deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)operation.request];
	}

	[self updateMessageStatusForOperation:operation];

	[self removeActiveOperation:operation];
}

#pragma mark - Update missing conversation IDs

- (void)updateQueuedRequestsInContext:(NSManagedObjectContext *)context missingConversationIdentifier:(NSString *)conversationIdentifier {
	// create a child context on a private concurrent queue
	NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	// set parent context
	[childContext setParentContext:context];

	// execute the block on a background thread (this call returns immediatelly)
	[childContext performBlock:^{

		// fetch all the requests without a conversation id (no sorting needed)
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"conversationIdentifier = nil"];

		NSError *fetchError;
		NSArray *queuedRequests = [childContext executeFetchRequest:fetchRequest error:&fetchError];
		if (fetchError != nil) {
			ApptentiveLogError(@"Error while fetching requests without a conversation id: %@", fetchError);
			return;
		}

		ApptentiveLogDebug(@"Fetched %d requests without a conversation id", queuedRequests.count);

		if (queuedRequests.count > 0) {

			// Set a new conversation identifier
			for (ApptentiveSerialRequest *requestInfo in queuedRequests) {
				requestInfo.conversationIdentifier = conversationIdentifier;
			}

			// save child context
			[childContext performBlockAndWait:^{
				NSError *saveError;
				if (![childContext save:&saveError]) {
					ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
				}
			}];

			// save parent context on the main thread
			dispatch_async(dispatch_get_main_queue(), ^{
				NSError *parentSaveError;
				if (![childContext.parentContext save:&parentSaveError]) {
					ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
				}

				// we call -createOperationsForQueuedRequestsInContext: to send everything
				[self createOperationsForQueuedRequestsInContext:context];
			});
		}
	}];
}

#pragma mark - Delete completed or failed requests

- (void)deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)requestToDelete {
	if ([requestToDelete isKindOfClass:[ApptentiveMessageSendRequest class]]) {
		// If this is a message send request, unwrap it to get the original ApptentiveSerialRequest object
		requestToDelete = ((ApptentiveMessageSendRequest *)requestToDelete).request;
	}

	if (requestToDelete != nil) {
		[requestToDelete.managedObjectContext performBlockAndWait:^{
			[requestToDelete.managedObjectContext deleteObject:requestToDelete];
		}];
	}
}

@end
