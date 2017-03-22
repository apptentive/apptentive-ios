//
//  ApptentiveMessageManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 3/21/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ApptentiveRequestOperation.h"

@class ApptentiveMessage, ApptentiveNetworkQueue;
@protocol ApptentiveMessageManagerDelegate;

@interface ApptentiveMessageManager : NSObject <ApptentiveRequestOperationDelegate>

@property (readonly, nonatomic) NSString *storagePath;
@property (readonly, nonatomic) ApptentiveNetworkQueue *networkQueue;
@property (assign, nonatomic) NSTimeInterval pollingInterval;

@property (readonly, nonatomic) NSInteger unreadCount;
@property (readonly, nonatomic) NSArray<ApptentiveMessage *> *messages;

@property (weak, nonatomic) id<ApptentiveMessageManagerDelegate> delegate;

- (instancetype)initWithStoragePath:(NSString *)storagePath networkQueue:(ApptentiveNetworkQueue *)networkQueue pollingInterval:(NSTimeInterval)pollingInterval;

- (void)checkForMessages;
- (void)stopPolling;



- (ApptentiveMessage *)automatedMessageWithTitle:(NSString *)title body:(NSString *)body;
- (BOOL)sendAutomatedMessage:(ApptentiveMessage *)message;

- (ApptentiveMessage *)createTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessageWithBody:(NSString *)body;
- (BOOL)sendTextMessageWithBody:(NSString *)body hiddenOnClient:(BOOL)hidden;
- (BOOL)sendTextMessage:(ApptentiveMessage *)message;

- (BOOL)sendImageMessageWithImage:(UIImage *)image;
- (BOOL)sendImageMessageWithImage:(UIImage *)image hiddenOnClient:(BOOL)hidden;

- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType;
- (BOOL)sendFileMessageWithFileData:(NSData *)fileData andMimeType:(NSString *)mimeType hiddenOnClient:(BOOL)hidden;

- (BOOL)sendCompoundMessageWithText:(NSString *)text attachments:(NSArray *)attachments hiddenOnClient:(BOOL)hidden;


@end

@protocol ApptentiveMessageManagerDelegate <NSObject>

- (void)messageManagerdidAppendMessage:(ApptentiveMessageManager *)manager didAppendMessage:(ApptentiveMessage *)message;
- (void)messageManager:(ApptentiveMessageManager *)manager didInsertMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index;

@end
