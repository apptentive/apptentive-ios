//
//  ApptentiveMessageManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveRequestOperation.h"
#import "ApptentiveMessage.h"

@class ApptentiveNetworkQueue, ApptentiveMessageStore;
@protocol ApptentiveMessageManagerDelegate;


@interface ApptentiveMessageManager : NSObject <ApptentiveRequestOperationDelegate>

@property (readonly, nonatomic) NSString *storagePath;
@property (readonly, nonatomic) ApptentiveNetworkQueue *networkQueue;
@property (assign, nonatomic) NSTimeInterval pollingInterval;
@property (readonly, nonatomic) NSString *localUserIdentifier;

@property (readonly, nonatomic) NSInteger unreadCount;
@property (readonly, nonatomic) NSArray<ApptentiveMessage *> *messages;

@property (weak, nonatomic) id<ApptentiveMessageManagerDelegate> delegate;

- (instancetype)initWithStoragePath:(NSString *)storagePath networkQueue:(ApptentiveNetworkQueue *)networkQueue pollingInterval:(NSTimeInterval)pollingInterval;

- (void)checkForMessages;
- (void)stopPolling;

- (BOOL)saveMessageStore;

- (NSInteger)numberOfMessages;

- (void)sendMessage:(ApptentiveMessage *)message;
- (void)enqueueMessageForSending:(ApptentiveMessage *)message;

- (void)appendMessage:(ApptentiveMessage *)message;
- (void)removeMessage:(ApptentiveMessage *)message;

- (void)setState:(ApptentiveMessageState)state forMessageWithLocalIdentifier:(NSString *)localIdentifier;
@end

@protocol ApptentiveMessageManagerDelegate <NSObject>

- (void)messageManagerWillBeginUpdates:(ApptentiveMessageManager *)manager;
- (void)messageManagerDidEndUpdates:(ApptentiveMessageManager *)manager;

- (void)messageManager:(ApptentiveMessageManager *)manager didInsertMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;
- (void)messageManager:(ApptentiveMessageManager *)manager didUpdateMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;
- (void)messageManager:(ApptentiveMessageManager *)manager didDeleteMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;

@end
