//
//  ApptentiveSerialNetworkQueue.m
//  Apptentive
//
//  Created by Frank Schmitt on 12/14/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSerialNetworkQueue.h"
#import "ApptentiveSerialRequest.h"
#import "ApptentiveSerialRequestOperation.h"
#import "ApptentiveMessageRequestOperation.h"
#import "ApptentiveConversationManager.h"

@interface ApptentiveSerialNetworkQueue ()

@property (strong, readonly, nonatomic) NSManagedObjectContext *parentManagedObjectContext;
@property (assign, atomic) BOOL isResuming;
@property (strong, nonatomic) NSMutableDictionary *activeTaskProgress;

@end


@implementation ApptentiveSerialNetworkQueue

- (instancetype)initWithBaseURL:(NSURL *)baseURL token:(NSString *)token SDKVersion:(NSString *)SDKVersion platform:(NSString *)platform parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext {
	self = [super initWithBaseURL:baseURL token:token SDKVersion:SDKVersion platform:platform];

	if (self) {
		_parentManagedObjectContext = parentManagedObjectContext;
		_activeTaskProgress = [NSMutableDictionary dictionary];

		self.maxConcurrentOperationCount = 1;
		_backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        
        [self registerNotifications];
	}

	return self;
}

- (void)dealloc {
    [self unregisterNotifications];
}

- (void)resume {
	if (self.isResuming) {
		return;
	}

	self.isResuming = YES;

	NSBlockOperation *resumeBlock = [NSBlockOperation blockOperationWithBlock:^{
		NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[moc setParentContext:self.parentManagedObjectContext];

		__block NSArray *queuedRequests;
		[moc performBlockAndWait:^{
			NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"QueuedRequest"];
			fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES] ];

			NSError *error;
			queuedRequests = [moc executeFetchRequest:fetchRequest error:&error];

			if (queuedRequests == nil) {
				ApptentiveLogError(@"Unable to fetch waiting network payloads.");
			}

			ApptentiveLogDebug(@"Adding %d record operations", queuedRequests.count);

			// Add an operation for every record in the queue
			for (ApptentiveSerialRequest *requestInfo in [queuedRequests copy]) {
				ApptentiveSerialRequestOperation *operation = [ApptentiveSerialRequestOperation operationWithRequestInfo:requestInfo delegate:self];
				[self addOperation:operation];
			}
		}];

		if (queuedRequests.count) {
			// Save the context after all enqueued records have been sent
			NSBlockOperation *saveBlock = [NSBlockOperation blockOperationWithBlock:^{
				[moc performBlockAndWait:^{
					NSError *saveError;
					if (![moc save:&saveError]) {
						ApptentiveLogError(@"Unable to save temporary managed object context: %@", saveError);
					}
				}];

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

			[self addOperation:saveBlock];
		}
		
		self.isResuming = NO;
	}];

	[self addOperation:resumeBlock];
}

- (void)cancelAllOperations {
	[super cancelAllOperations];

	self.isResuming = NO;
}

- (void)requestOperationDidStart:(ApptentiveRequestOperation *)operation {
	[self addActiveOperation:operation];
}

- (void)requestOperationWillRetry:(ApptentiveRequestOperation *)operation withError:(NSError *)error {
	if (error) {
		_status = ApptentiveQueueStatusError;

		[self updateMessageErrorStatus];

		ApptentiveLogError(@"%@ %@ failed with error: %@", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);
	}

	ApptentiveLogInfo(@"%@ %@ will retry in %f seconds.", operation.request.HTTPMethod, operation.request.URL.absoluteString, self.backoffDelay);

	[self removeActiveOperation:operation];
}

- (void)requestOperationDidFinish:(ApptentiveRequestOperation *)operation {
	_status = ApptentiveQueueStatusGroovy;

	[self updateMessageErrorStatus];

	ApptentiveLogDebug(@"%@ %@ finished successfully.", operation.request.HTTPMethod, operation.request.URL.absoluteString);

	[self removeActiveOperation:operation];
}

- (void)requestOperation:(ApptentiveRequestOperation *)operation didFailWithError:(NSError *)error {
	_status = ApptentiveQueueStatusError;

	[self updateMessageErrorStatus];

	ApptentiveLogError(@"%@ %@ failed with error: %@. Not retrying.", operation.request.HTTPMethod, operation.request.URL.absoluteString, error);

	[self removeActiveOperation:operation];
}

#pragma mark - URL Session Data Delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
	if (self.activeTaskProgress[@(task.taskIdentifier)]) {
		self.activeTaskProgress[@(task.taskIdentifier)] = [NSNumber numberWithDouble:(double)totalBytesSent / (double)totalBytesExpectedToSend];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateProgress];
		});
	}
}

- (void)updateProgress {
	[self willChangeValueForKey:@"messageSendProgress"];

	if (self.activeTaskProgress.count == 0) {
		_messageSendProgress = nil;
	} else {
		_messageSendProgress = [self.activeTaskProgress.allValues valueForKeyPath:@"@avg.self"];
	}
	[self didChangeValueForKey:@"messageSendProgress"];
}

- (void)addActiveOperation:(ApptentiveRequestOperation *)operation {
	if ([operation isKindOfClass:[ApptentiveMessageRequestOperation class]]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self willChangeValueForKey:@"messageTaskCount"];
			[self.activeTaskProgress setObject:@0 forKey:@(operation.task.taskIdentifier)];
			[self didChangeValueForKey:@"messageTaskCount"];
		});
	}
}

- (void)removeActiveOperation:(ApptentiveRequestOperation *)operation {
	NSNumber *identifier = @(operation.task.taskIdentifier);

	if (self.activeTaskProgress[identifier]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self willChangeValueForKey:@"messageTaskCount"];
			[self.activeTaskProgress removeObjectForKey:identifier];
			[self didChangeValueForKey:@"messageTaskCount"];
		});
	}
}

- (void)updateMessageErrorStatus {
	ATPendingMessageState pendingMessageState = (self.status == ApptentiveQueueStatusError) ? ATPendingMessageStateError : ATPendingMessageStateSending;

	for (NSOperation *operation in self.operations) {
		if ([operation isKindOfClass:[ApptentiveMessageRequestOperation class]]) {
			[(ApptentiveMessageRequestOperation *)operation setMessagePendingState:pendingMessageState];
		}
	}
}

- (NSInteger)messageTaskCount {
	return self.activeTaskProgress.count;
}

#pragma mark -
#pragma mark Notifications

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(conversationStateDidChangeNotification:)
                                                 name:ApptentiveConversationStateDidChangeNotification
                                               object:nil];
}

- (void)unregisterNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)conversationStateDidChangeNotification:(NSNotification *)notification {
    
}

@end
