//
//  ApptentivePayloadSender.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/25/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClient.h"

@protocol ApptentivePayloadSenderDelegate;
@class ApptentiveClient;

typedef NS_ENUM(NSInteger, ApptentiveQueueStatus) {
	ApptentiveQueueStatusUnknown,
	ApptentiveQueueStatusError,
	ApptentiveQueueStatusGroovy
};


@interface ApptentivePayloadSender : ApptentiveClient <ApptentiveRequestOperationDelegate, ApptentiveRequestOperationDataSource>

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) id<ApptentivePayloadSenderDelegate> messageDelegate;

- (instancetype)initWithBaseURL:(NSURL *)baseURL apptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)cancelNetworkOperations;

#pragma mark - Serial network queue

/**
 Instructs the client to read any pending request information from Core Data and
 create an `ApptentiveSerialRequestOperation` instance for each of them. These
 operations are then enqueued, followed by an operation that saves the private
 context to its parent, and saves the parent context to disk.

 @param context The managed object context in which to look for pending network payloads.
 */
- (void)createOperationsForQueuedRequestsInContext:(NSManagedObjectContext *)context;

/**
 Adds a conversation identifier to pending requests that are missing one.

 @param context The managed object context in which to look for pending network payloads.
 @param conversationIdentifier The value to use for the conversationIdentifier property of the queued requests.
 */
- (void)updateQueuedRequestsInContext:(NSManagedObjectContext *)context missingConversationIdentifier:(NSString *)conversationIdentifier;

/**
 A number representing the average progress across all message operations in the
 queue.
 */
@property (readonly, nonatomic) float messageSendProgress;

/**
 The status (success or failure) of the most recently-sent request in the queue.
 */
@property (readonly, nonatomic) ApptentiveQueueStatus status;

/**
 A background task identifier, used on iOS to complete the parent context save
 operation when an app is closed.
 */
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@protocol ApptentivePayloadSenderDelegate <NSObject>

- (void)payloadSender:(ApptentivePayloadSender *)sender setState:(ApptentiveMessageState)state forMessageWithLocalIdentifier:(NSString *)localIdentifier;
- (void)payloadSenderProgressDidChange:(ApptentivePayloadSender *)sender;

@end
