//
//  ApptentiveMessageManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessage.h"
#import "ApptentivePayloadSender.h"
#import "ApptentiveRequestOperation.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ApptentiveMessageStore, ApptentiveClient, ApptentiveDispatchQueue;
@protocol ApptentiveMessageManagerDelegate;


@interface ApptentiveMessageManager : NSObject <ApptentivePayloadSenderDelegate>

@property (readonly, nonatomic) NSString *storagePath;
@property (readonly, nonatomic) NSString *conversationIdentifier;
@property (readonly, nonatomic) ApptentiveDispatchQueue *operationQueue;
@property (readonly, nonatomic) ApptentiveConversation *conversation;

@property (readonly, nonatomic) ApptentiveClient *client;
@property (assign, nonatomic) NSTimeInterval pollingInterval;
@property (copy, nonatomic) NSString *localUserIdentifier;

@property (readonly, nonatomic) NSArray<ApptentiveMessage *> *messages;

@property (weak, nonatomic) id<ApptentiveMessageManagerDelegate> delegate;

@property (strong, nonatomic) NSString *draftMessage;
@property (assign, nonatomic) BOOL didSkipProfile;

- (instancetype)initWithStoragePath:(NSString *)storagePath client:(ApptentiveClient *)client pollingInterval:(NSTimeInterval)pollingInterval conversation:(ApptentiveConversation *)conversation operationQueue:(ApptentiveDispatchQueue *)operationQueue;

- (void)checkForMessages;

- (void)checkForMessagesInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;

- (void)stop;

- (void)stopPolling;

- (BOOL)saveMessageStore;

- (NSInteger)numberOfMessages;

- (void)sendMessage:(ApptentiveMessage *)message;
- (void)enqueueMessageForSending:(ApptentiveMessage *)message;
- (void)enqueueMessageForSendingOnBackgroundQueue:(ApptentiveMessage *)message;

- (void)appendMessage:(ApptentiveMessage *)message;
- (void)removeMessage:(ApptentiveMessage *)message;

- (void)updateUnreadCount;

+ (NSString *)attachmentDirectoryPathForConversationDirectory:(NSString *)storagePath;

@property (readonly, nonatomic) NSString *attachmentDirectoryPath;

@end

@protocol ApptentiveMessageManagerDelegate <NSObject>

- (void)messageManagerWillBeginUpdates:(ApptentiveMessageManager *)manager;
- (void)messageManagerDidEndUpdates:(ApptentiveMessageManager *)manager;

- (void)messageManager:(ApptentiveMessageManager *)manager didInsertMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;
- (void)messageManager:(ApptentiveMessageManager *)manager didUpdateMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;
- (void)messageManager:(ApptentiveMessageManager *)manager didDeleteMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;

- (void)messageManager:(ApptentiveMessageManager *)manager messageSendProgressDidUpdate:(float)progress;

@end

NS_ASSUME_NONNULL_END
