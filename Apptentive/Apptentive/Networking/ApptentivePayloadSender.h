//
//  ApptentivePayloadSender.h
//  Apptentive
//
//  Created by Frank Schmitt on 4/25/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentivePayloadSenderDelegate;

@class ApptentiveClient;
@class ApptentiveConversation;
@class ApptentiveDispatchQueue;

typedef NS_ENUM(NSInteger, ApptentiveQueueStatus) {
	ApptentiveQueueStatusUnknown,
	ApptentiveQueueStatusError,
	ApptentiveQueueStatusGroovy
};


@interface ApptentivePayloadSender : ApptentiveClient <ApptentiveRequestOperationDataSource>

@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) id<ApptentivePayloadSenderDelegate> messageDelegate;

- (instancetype)initWithBaseURL:(NSURL *)baseURL apptentiveKey:(NSString *)apptentiveKey apptentiveSignature:(NSString *)apptentiveSignature managedObjectContext:(NSManagedObjectContext *)managedObjectContext delegateQueue:(ApptentiveDispatchQueue *)delegateQueue;
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
 Adds a conversation identifier and token to pending requests that are missing them.

 @param context The managed object context in which to look for pending network payloads.
 @param conversation The conversation to use for the queued requests.
 */
- (void)updateQueuedRequestsInContext:(NSManagedObjectContext *)context withConversation:(ApptentiveConversation *)conversation;

/**
 A number representing the average progress across all message operations in the
 queue.
 */
@property (readonly, nonatomic) float messageSendProgress;

/**
 The status (success or failure) of the most recently-sent request in the queue.
 */
@property (readonly, nonatomic) ApptentiveQueueStatus status;

@property (readonly, weak, nonatomic) NSOperation *saveContextOperation;

@end

@protocol ApptentivePayloadSenderDelegate <NSObject>

- (void)payloadSender:(ApptentivePayloadSender *)sender setState:(ApptentiveMessageState)state forMessageWithLocalIdentifier:(NSString *)localIdentifier;
- (void)payloadSenderProgressDidChange:(ApptentivePayloadSender *)sender toValue:(double)value;

@end

NS_ASSUME_NONNULL_END
