//
//  ApptentiveConversationManager.m
//  Apptentive
//
//  Created by Frank Schmitt on 2/20/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversationManager.h"
#import "ApptentiveConversationMetadata.h"

static NSString *const ConversationMetadataFilename = @"conversation-v1.meta";


@interface ApptentiveConversationManager ()

@property (strong, nonatomic) ApptentiveConversationMetadata *conversationMetadata;
@property (readonly, nonatomic) NSString *metadataPath;

- (void)loadConversation;
- (void)fetchConversationToken;
- (void)setActiveConversation:(ApptentiveConversation *)conversation;
- (void)scheduleConversationSave;
- (void)saveConversation;

@end


@implementation ApptentiveConversationManager

- (instancetype)initWithStoragePath:(NSString *)storagePath operationQueue:(NSOperationQueue *)operationQueue {
	self = [super init];

	if (self) {
		_storagePath = storagePath;
		_conversationMetadata = [NSKeyedUnarchiver unarchiveObjectWithFile:self.metadataPath];
		_operationQueue = operationQueue;
	}

	return self;
}

- (BOOL)loadActiveConversation {
	return NO;
}

- (BOOL)saveMetadata {
	return [NSKeyedArchiver archiveRootObject:self.conversationMetadata toFile:self.metadataPath];
}

#pragma mark - Conversation Delegate

- (void)conversation:(ApptentiveConversation *)conversation deviceDidChange:(NSDictionary *)diffs {
	// kick off device update request

	// queue up save request
}

- (void)conversation:(ApptentiveConversation *)conversation personDidChange:(NSDictionary *)diffs {
	// kick off person update request

	// queue up save request
}

- (void)conversationUserInfoDidChange:(ApptentiveConversation *)conversation {
	// queue up save request
}

- (void)conversationEngagementDidChange:(ApptentiveConversation *)conversation {
	// queue up save request
}

#pragma mark - Private

- (NSString *)metadataPath {
	return [self.storagePath stringByAppendingPathComponent:ConversationMetadataFilename];
}

- (ApptentiveConversationMetadataItem *)firstConversationPassingTest:(BOOL (^)(ApptentiveConversationMetadataItem *))filterBlock {
	for (ApptentiveConversationMetadataItem *item in self.conversationMetadata.items) {
		if (filterBlock(item)) {
			return item;
		}
	}

	return nil;
}

@end
