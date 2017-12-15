//
//  ApptentiveConversationManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"
#import "ApptentiveRequestOperation.h"
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class ApptentiveConversationMetadata, ApptentiveConversationMetadataItem, ApptentiveConversation, ApptentiveClient, ApptentiveEngagementManifest, ApptentiveAppConfiguration, ApptentiveMessageManager, ApptentiveDispatchQueue;

@protocol ApptentiveConversationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ApptentiveConversationStateDidChangeNotification;
extern NSString *const ApptentiveConversationStateDidChangeNotificationKeyConversation;


@interface ApptentiveConversationManager : NSObject <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;
@property (readonly, strong, nonatomic) NSString *storagePath;
@property (readonly, strong, nonatomic) ApptentiveDispatchQueue *operationQueue;
@property (readonly, strong, nonatomic) ApptentiveClient *client;
@property (strong, nullable, nonatomic) ApptentiveRequestOperation *conversationOperation;
@property (readonly, strong, nullable, nonatomic) ApptentiveConversation *activeConversation;
@property (readonly, strong, nullable, nonatomic) ApptentiveMessageManager *messageManager;

@property (weak, nonatomic) id<ApptentiveConversationManagerDelegate> delegate;

@property (readonly, strong, nonatomic) ApptentiveEngagementManifest *manifest;

@property (readonly, strong, nonatomic) NSManagedObjectContext *parentManagedObjectContext;

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(ApptentiveDispatchQueue *)operationQueue client:(ApptentiveClient *)client parentManagedObjectContext:(NSManagedObjectContext *)parentManagedObjectContext;

/**
 * Attempts to load an active conversation.
 * Returns NO if active conversation is missing or cannot be loaded.
 */
- (BOOL)loadActiveConversation;
- (void)endActiveConversation;
- (void)logInWithToken:(NSString *)token completion:(void (^)(BOOL success, NSError *error))completion;

- (BOOL)saveMetadata;

- (void)completeHousekeepingTasks;

- (void)pause;

// Debugging

@property (strong, nonatomic) NSURL *localEngagementManifestURL;

- (void)createMessageManagerForConversation:(ApptentiveConversation *)conversation;

@end

@protocol ApptentiveConversationManagerDelegate <NSObject>

- (void)conversationManager:(ApptentiveConversationManager *)manager conversationDidChangeState:(ApptentiveConversation *)conversation;
- (void)processQueuedRecords;

@end

NS_ASSUME_NONNULL_END
