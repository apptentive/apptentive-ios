//
//  ApptentiveConversationManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationManager.h"
#import "ApptentiveConversationMetadata.h"
#import "ApptentiveConversationMetadataItem.h"
#import "ApptentiveUtilities.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";

@interface ApptentiveConversationManager () <ApptentiveConversationDelegate>

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;
@property (readonly, nonatomic) NSString *metadataPath;

@end

@implementation ApptentiveConversationManager

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_operationQueue = operationQueue;
	}

	return self;
}

#pragma mark - Conversations

- (BOOL)loadActiveConversation {
    
    // resolve metadata
    _conversationMetadata = [self resolveMetadata];
    
    // try to load conversaton
    _activeConversation = [self loadActiveConversationFromMetadata:_conversationMetadata];
    if (_activeConversation) {
        _activeConversation.delegate = self;
        [self notifyConversationDidBecomeActive];
        return YES;
    }
    
    // no convesation - fetch one
    [self fetchConversationToken];
    
    return NO;
}

- (ApptentiveConversation *)loadActiveConversationFromMetadata:(ApptentiveConversationMetadata *)metadata {
    // if the user was logged in previously - we should have an active conversation
    ApptentiveLogDebug(@"Loading active conversation...");
    ApptentiveConversationMetadataItem *activeItem = [metadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.isActive;
    }];
    
    if (activeItem) {
        return [self loadConversation:activeItem];
    }
    
    // if no user was logged in previously - we might have a default conversation
    ApptentiveLogDebug(@"Loading default conversation...");
    ApptentiveConversationMetadataItem *defaultItem = [metadata findItemFilter:^BOOL(ApptentiveConversationMetadataItem *item) {
        return item.isDefault;
    }];
    
    if (defaultItem) {
        return [self loadConversation:defaultItem];
    }
    
    // TODO: check for legacy conversations
    ApptentiveLogDebug(@"Can't load conversation");
    return nil;
}

- (void)notifyConversationDidBecomeActive {
    
}

#pragma mark - Metadata

- (ApptentiveConversationMetadata *)resolveMetadata {

    if ([ApptentiveUtilities fileExistsAtPath:self.metadataPath]) {
        ApptentiveConversationMetadata *metadata = [NSKeyedUnarchiver unarchiveObjectWithFile:self.metadataPath];
        // TODO: dispatch debug event
        return metadata;
    }
    
    return [[ApptentiveConversationMetadata alloc] init];
}

- (BOOL)saveMetadata {
    return [NSKeyedArchiver archiveRootObject:self.conversationMetadata toFile:self.metadataPath];
}

#pragma mark - ApptentiveConversationDelegate

/**
 Indicates that the conversation object (any of its parts) has changed.
 
 @param conversation The conversation associated with the change.
 server.
 */
- (void)conversationDidChange:(ApptentiveConversation *)conversation {
    [self scheduleConversationSave];
}

/**
 Indicates that the device object has changed.
 
 @param conversation The conversation associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	// TODO: kick off device update request (Extract from ApptentiveBackend)
}

/**
 Indicates that the person object has changed.
 
 @param conversation The conversation associated with the change.
 @param diffs A dictionary suitable for encoding as JSON and sending to the
 server.
 */
- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	// TODO: kick off person update request (Extract from ApptentiveBackend)
}

/**
 Indicates that the user info has changed
 
 @param conversation The session associated with the change.
 */
- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
}

/**
 Indicates that the engagement data has changed.
 
 @param conversation The conversation associated with the change.
 */
- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
}

#pragma mark - Private

- (void)fetchConversationToken {
	// TODO: Extract from ApptentiveBackend
}

- (void)setActiveConversation:(ApptentiveConversation *)conversation {
	_activeConversation = conversation;

	// TODO: Add any necessary side effects
	// Such as marking this conversation as active in the metadata
	// and clearing the active flag on previously active convo
}

- (void)scheduleConversationSave {
	[self.operationQueue addOperationWithBlock:^{
		if (![self saveConversation]) {
			ApptentiveLogError(@"Error saving active conversation.");
		}
	}];
}

- (ApptentiveConversation *)loadConversation:(ApptentiveConversationMetadataItem *)metadataItem {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:metadataItem.fileName];
}

- (BOOL)saveConversation {
	NSString *path = @""; // TODO: Generate path
	return [NSKeyedArchiver archiveRootObject:self.activeConversation toFile:path];
}

#pragma mark - Paths

- (NSString *)metadataPath {
	return [self.storagePath stringByAppendingPathComponent:ConversationMetadataFilename];
}

- (NSString *)conversationPathForFilename:(NSString *)filename {
	return [self.storagePath stringByAppendingPathComponent:filename];
}

@end
