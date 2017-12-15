//
//  ApptentivePayloadSender.m
//  Apptentive
//
//  Created by Frank Schmitt on 4/25/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentivePayloadSender.h"
#import "ApptentiveClient.h"
#import "ApptentiveConversation.h"
#import "ApptentivePayloadDebug.h"
#import "ApptentiveSerialRequest.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ApptentiveBuildPayloadRequestsName = @"Build Payload Requests";


@interface ApptentivePayloadSender ()

/*!
 * This private serial queue is used for sending payloads one-by-one (also retrying)
 */

@property (strong, nonatomic) NSMutableDictionary *activeTaskProgress;
@property (assign, atomic) BOOL isResuming;

/**
 A background task identifier, used on iOS to complete the parent context save
 operation when an app is closed.
 */
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end


@implementation ApptentivePayloadSender

- (instancetype)initWithBaseURL:(NSURL *)baseURL apptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature managedObjectContext:(NSManagedObjectContext *)managedObjectContext delegateQueue:(ApptentiveDispatchQueue *)delegateQueue {
	self = [super initWithBaseURL:baseURL apptentiveKey:apptentiveKey apptentiveSignature:apptentiveSignature delegateQueue:delegateQueue];

	if (self) {
		self.networkQueue.maxConcurrentOperationCount = 1;
		self.networkQueue.name = @"Payload Queue";

		_managedObjectContext = managedObjectContext;
		_activeTaskProgress = [[NSMutableDictionary alloc] init];
	}

	return self;
}

#pragma mark - Cancelling network operations

- (void)cancelNetworkOperations {
	for (NSOperation *operation in self.networkQueue.operations) {
		if ([operation isKindOfClass:[ApptentiveRequestOperation class]]) {
			ApptentiveLogVerbose(@"Cancelling request operation %@.", operation.name);
			[operation cancel];
		} else if ([operation.name isEqualToString:ApptentiveBuildPayloadRequestsName]) {
			ApptentiveLogVerbose(@"Cancelling build payload requets operation.");
			[operation cancel];
		}
	}

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Clearing isResuming Flag");
	self.isResuming = NO;
}

#pragma mark - Creating network operations from queued payloads

- (void)createOperationsForQueuedRequestsInContext:(NSManagedObjectContext *)context {
	ApptentiveAssertNotNil(context, @"Context is nil");
	if (context == nil) {
		return;
	}

	if (self.isResuming) {
		ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Already creating operations for queued payloads. Skipping.");
		return;
	}

	ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Setting isResuming Flag");
	self.isResuming = YES;

	NSBlockOperation *buildPayloadRequestsOperation = [NSBlockOperation blockOperationWithBlock:^{
	  NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	  [childContext setParentContext:context];

	  __block NSArray *queuedRequests;
	  [childContext performBlockAndWait:^{
		[ApptentivePayloadDebug printPayloadSendingQueueWithContext:childContext title:@"Sending payloads..."];

		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
		fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
		fetchRequest.predicate = [NSPredicate predicateWithFormat:@"conversationIdentifier != nil"]; // make sure we don't include "anonymous" conversation here

		NSError *error;
		queuedRequests = [childContext executeFetchRequest:fetchRequest error:&error];

		if (queuedRequests == nil) {
			ApptentiveLogError(ApptentiveLogTagPayload, @"Unable to fetch waiting network payloads.");
		}

		ApptentiveLogDebug(ApptentiveLogTagPayload, @"Adding %d record operations for queued payloads", queuedRequests.count);

		// Add an operation for every record in the queue
		// When the operation succeeds (or fails permanently), it deletes the associated record
		for (ApptentiveSerialRequest *request in queuedRequests) {
			ApptentiveAssertNotNil(request.authToken, @"Attempted to send a request without a token: %@", request);
			ApptentiveRequestOperationCallback *callback = [ApptentiveRequestOperationCallback new];
			callback.operationStartCallback = ^(ApptentiveRequestOperation *operation) {
			  [self requestOperationDidStart:operation];
			};
			callback.operationFinishCallback = ^(ApptentiveRequestOperation *operation) {
			  [self requestOperationDidFinish:operation];
			};
			callback.operationFailCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
			  [self requestOperation:operation didFailWithError:error];
			};
			callback.operationRetryCallback = ^(ApptentiveRequestOperation *operation, NSError *error) {
			  [self requestOperationWillRetry:operation withError:error];
			};

			ApptentiveRequestOperation *operation = [self requestOperationWithRequest:request token:request.authToken delegate:callback];
			ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Adding operation for %@ %@", operation.URLRequest.HTTPMethod, operation.URLRequest.URL.absoluteString);

			operation.request = request;

			[self.networkQueue addOperation:operation];
		}
	  }];

	  if (queuedRequests.count) {
		  // Save the context after all enqueued records have been sent
		  NSBlockOperation *saveBlockOperation = [NSBlockOperation blockOperationWithBlock:^{
			ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Saving Private Managed Object Context (with completed payloads deleted)");
			[childContext performBlockAndWait:^{
			  NSError *saveError;
			  if (![childContext save:&saveError]) {
				  ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
				  return;
			  }

			  ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Saving Parent Managed Object Context (with completed payloads deleted)");
			  [context performBlockAndWait:^{
				NSError *parentSaveError;
				if (![context save:&parentSaveError]) {
					ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
				}
			  }];
			}];
		  }];

		  saveBlockOperation.name = @"Save Child & Parent Context";

		  _saveContextOperation = saveBlockOperation;

		  [self.networkQueue addOperation:saveBlockOperation];
	  }

	  ApptentiveLogVerbose(ApptentiveLogTagPayload, @"Clearing isResuming Flag");
	  self.isResuming = NO;
	}];

	buildPayloadRequestsOperation.name = ApptentiveBuildPayloadRequestsName;

	[self.networkQueue addOperation:buildPayloadRequestsOperation];
}

#pragma mark - Message send progress

#pragma mark URL sesison delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
	if (self.activeTaskProgress[@(task.taskIdentifier)]) {
		self.activeTaskProgress[@(task.taskIdentifier)] = [NSNumber numberWithDouble:(double)totalBytesSent / (double)totalBytesExpectedToSend];
		[self updateProgress];
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
		  [self.messageDelegate payloadSenderProgressDidChange:self toValue:messageSendProgress];
		});
	}
}

- (void)addActiveOperation:(ApptentiveRequestOperation *)operation {
	if (((ApptentiveSerialRequest *)operation.request).messageRequest) {
		[self.activeTaskProgress setObject:@0 forKey:@(operation.task.taskIdentifier)];
		[self updateProgress];
	}
}

- (void)removeActiveOperation:(ApptentiveRequestOperation *)operation {
	if (((ApptentiveSerialRequest *)operation.request).messageRequest) {
		[self.activeTaskProgress removeObjectForKey:@(operation.task.taskIdentifier)];
		[self updateProgress];
	}
}

- (void)updateMessageStatusForOperation:(ApptentiveRequestOperation *)operation {
	for (NSOperation *operation in self.networkQueue.operations) {
		if ([operation isKindOfClass:[ApptentiveRequestOperation class]] && [((ApptentiveRequestOperation *)operation).request isKindOfClass:[ApptentiveSerialRequest class]] && ((ApptentiveSerialRequest *)((ApptentiveRequestOperation *)operation).request).messageRequest) {
			ApptentiveRequestOperation *messageOperation = (ApptentiveRequestOperation *)operation;
			ApptentiveSerialRequest *messageSendRequest = (ApptentiveSerialRequest *)messageOperation.request;
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

	if ([operation.request isKindOfClass:[ApptentiveSerialRequest class]] || ((ApptentiveSerialRequest *)operation.request).messageRequest) {
		[self deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)operation.request];
	}

	[self updateMessageStatusForOperation:operation];

	[self removeActiveOperation:operation];
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	_status = ApptentiveQueueStatusError;

	if ([operation.request isKindOfClass:[ApptentiveSerialRequest class]] || ((ApptentiveSerialRequest *)operation.request).messageRequest) {
		[self deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)operation.request];
	}

	[self updateMessageStatusForOperation:operation];

	[self removeActiveOperation:operation];
}

#pragma mark - Update missing conversation IDs

- (void)updateQueuedRequestsInContext:(NSManagedObjectContext *)context withConversation:(ApptentiveConversation *)conversation {
	ApptentiveAssertNotNil(context, @"Context is nil");
	if (context == nil) {
		return;
	}

	ApptentiveAssertNotNil(conversation, @"Conversation is nil");

	NSString *conversationToken = conversation.token;
	ApptentiveAssertTrue(conversationToken.length > 0, @"Conversation token is nil or empty");

	NSString *conversationIdentifier = conversation.identifier;
	ApptentiveAssertTrue(conversationIdentifier.length > 0, @"Conversation identifier is nil or empty");

	if (conversationToken.length == 0 || conversationIdentifier.length == 0) {
		return;
	}

	// create a child context on a private concurrent queue
	NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

	// set parent context
	[childContext setParentContext:context];

	// execute the block synchronously
	// otherwise it creates a race condition as described here: https://stackoverflow.com/questions/5749426/how-do-i-set-up-a-nspredicate-to-look-for-objects-that-have-a-nil-attribute/47760129#47760129
	[childContext performBlockAndWait:^{

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
			  ApptentiveAssertNil(requestInfo.authToken, @"Conversation token already set");

			  requestInfo.authToken = conversationToken;
			  requestInfo.conversationIdentifier = conversationIdentifier;
		  }

		  // save child context
		  NSError *saveError;
		  if (![childContext save:&saveError]) {
			  ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
		  }

		  [context performBlockAndWait:^{
			NSError *parentSaveError;
			if (![context save:&parentSaveError]) {
				ApptentiveLogError(@"Unable to save parent managed object context: %@", parentSaveError);
			}

			// we call -createOperationsForQueuedRequestsInContext: to send everything
			[self createOperationsForQueuedRequestsInContext:context];
		  }];

		  [ApptentivePayloadDebug printPayloadSendingQueueWithContext:childContext title:@"Recently Added CIDs"];
	  }
	}];
}

#pragma mark - Delete completed or failed requests

- (void)deleteCompletedOrFailedRequest:(ApptentiveSerialRequest *)requestToDelete {
	if (requestToDelete != nil) {
		NSManagedObjectContext *managedObjectContext = requestToDelete.managedObjectContext;

		[managedObjectContext performBlockAndWait:^{
		  [managedObjectContext deleteObject:requestToDelete];
		  [ApptentivePayloadDebug printPayloadSendingQueueWithContext:managedObjectContext title:@"Deleted payload"];
		}];
	}
}

@end

NS_ASSUME_NONNULL_END
