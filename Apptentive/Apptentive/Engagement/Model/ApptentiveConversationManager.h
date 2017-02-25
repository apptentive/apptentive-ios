//
//  ApptentiveConversationManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveConversation.h"
#import "ApptentiveRequestOperation.h"

@class ApptentiveConversationMetadataItem, ApptentiveConversation, ApptentiveNetworkQueue, ApptentiveEngagementManifest, ApptentiveAppConfiguration;

@protocol ApptentiveConversationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveConversationManager : NSObject <ApptentiveConversationDelegate, ApptentiveRequestOperationDelegate>

@property (readonly, strong, nonatomic) NSString *storagePath;
@property (readonly, strong, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, strong, nonatomic) ApptentiveNetworkQueue *networkQueue;
@property (readonly, strong, nullable, nonatomic) ApptentiveConversation *activeConversation;

@property (weak, nonatomic) id<ApptentiveConversationManagerDelegate> delegate;

@property (strong, nonatomic) ApptentiveEngagementManifest *manifest;
@property (strong, nonatomic) ApptentiveAppConfiguration *configuration;

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue networkQueue:(ApptentiveNetworkQueue *)networkQueue;

/**
 * Attempts to load an active conversation.
 * Returns NO if active conversation is missing or cannot be loaded.
 */
- (BOOL)loadActiveConversation;

- (BOOL)saveMetadata;

- (void)checkForMessages;

- (void)resume;

- (void)pause;


// Debugging

@property (strong, nonatomic) NSURL *localEngagementManifestURL;

@end

@protocol ApptentiveConversationManagerDelegate <NSObject>

- (void)conversationManager:(ApptentiveConversationManager *)manager didLoadConversation:(ApptentiveConversation *)conversation;

- (void)conversationManagerMessageFetchCompleted:(BOOL)success;

@end

NS_ASSUME_NONNULL_END
