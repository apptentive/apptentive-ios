//
//  ATMessageCenterDataSource.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ATMessage.h"

typedef NS_ENUM(NSInteger, ATMessageCenterMessageType) {
	ATMessageCenterMessageTypeMessage,
	ATMessageCenterMessageTypeReply,
	ATMessageCenterMessageTypeContextMessage,
	ATMessageCenterMessageTypeCompoundMessage
};

typedef NS_ENUM(NSInteger, ATMessageCenterMessageStatus) {
	ATMessageCenterMessageStatusHidden,
	ATMessageCenterMessageStatusSending,
	ATMessageCenterMessageStatusSent,
	ATMessageCenterMessageStatusFailed,
};

@protocol ATMessageCenterDataSourceDelegate;

@interface ATMessageCenterDataSource : NSObject
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedMessagesController;
@property (nonatomic, weak) NSObject<ATMessageCenterDataSourceDelegate> *delegate;
@property (nonatomic, readonly) NSDateFormatter *dateFormatter;

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)delegate;
- (void)start;
- (void)stop;

- (BOOL)hasNonContextMessages;

- (NSInteger)numberOfMessageGroups;
- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex;
- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)dateOfMessageGroupAtIndex:(NSInteger)index;
- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldShowDateForMessageGroupAtIndex:(NSInteger)index;
- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath;
- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeUnsentContextMessages;

- (NSInteger)numberOfAttachmentsForMessageAtIndex:(NSInteger)index;
- (NSString *)extensionForAttachmentAtIndexPath:(NSIndexPath *)indexPath; // Returns nil if thumbnail is present, file extension if not
- (UIImage *)imageForAttachmentAtIndexPath:(NSIndexPath *)indexPath; // Returns thumbnail if present, generic file icon if not

@property (nonatomic, readonly) BOOL lastMessageIsReply;
@property (nonatomic, readonly) NSIndexPath *lastUserMessageIndexPath;
@property (nonatomic, readonly) ATPendingMessageState lastUserMessageState;

@end

@protocol ATMessageCenterDataSourceDelegate <NSObject, NSFetchedResultsControllerDelegate>

- (void)messageCenterDataSource:(ATMessageCenterDataSource *)dataSource didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath;

@end
