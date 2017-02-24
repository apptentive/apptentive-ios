//
//  ApptentiveConversationManager.h
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ApptentiveConversation.h"

@class ApptentiveConversationMetadataItem, ApptentiveConversation;

@protocol ApptentiveConversationManagerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ApptentiveConversationManager : NSObject

@property (readonly, strong, nonatomic) NSString *storagePath;
@property (readonly, strong, nonatomic) NSOperationQueue *operationQueue;
@property (readonly, strong, nullable, nonatomic) ApptentiveConversation *activeConversation;

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue;

/**
 * Attempts to load an active conversation.
 * Returns NO if active conversation is missing or cannot be loaded.
 */
- (BOOL)loadActiveConversation;

- (BOOL)saveMetadata;

@end

@protocol ApptentiveConversationManagerDelegate <NSObject>

- (void)conversationManager:(ApptentiveConversationManager *)manager didLoadConversation:(ApptentiveConversation *)conversation;

@end

NS_ASSUME_NONNULL_END
