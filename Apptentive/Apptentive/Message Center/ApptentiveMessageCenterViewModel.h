//
//  ApptentiveMessageCenterViewModel.h
//  Apptentive
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveBackend.h"
#import "ApptentiveMessage.h"
#import "ApptentiveMessageManager.h"
#import <QuickLook/QuickLook.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ATMessageCenterMessageType) {
	ATMessageCenterMessageTypeMessage,
	ATMessageCenterMessageTypeReply,
	ATMessageCenterMessageTypeContextMessage,
	ATMessageCenterMessageTypeCompoundMessage,
	ATMessageCenterMessageTypeCompoundReply
};

typedef NS_ENUM(NSInteger, ATMessageCenterMessageStatus) {
	ATMessageCenterMessageStatusHidden,
	ATMessageCenterMessageStatusSending,
	ATMessageCenterMessageStatusSent,
	ATMessageCenterMessageStatusFailed,
};

@protocol ApptentiveMessageCenterViewModelDelegate
, ApptentiveStyle;

@class ApptentiveInteraction;


@interface ApptentiveMessageCenterViewModel : NSObject <NSURLSessionDownloadDelegate, ApptentiveMessageManagerDelegate>

@property (weak, nonatomic) NSObject<ApptentiveMessageCenterViewModelDelegate> *delegate;

@property (readonly, nonatomic) NSDateFormatter *dateFormatter;
@property (readonly, nonatomic) ApptentiveInteraction *interaction;
@property (readonly, nonatomic) ApptentiveMessageManager *messageManager;

@property (readonly, nonatomic) id<ApptentiveStyle> styleSheet;

@property (readonly, nonatomic) NSString *title;
@property (readonly, nonatomic) NSString *branding;

@property (readonly, nonatomic) NSString *composerTitle;
@property (readonly, nonatomic) NSString *composerPlaceholderText;
@property (readonly, nonatomic) NSString *composerSendButtonTitle;
@property (readonly, nonatomic) NSString *composerCloseConfirmBody;
@property (readonly, nonatomic) NSString *composerCloseDiscardButtonTitle;
@property (readonly, nonatomic) NSString *composerCloseCancelButtonTitle;

@property (readonly, nonatomic) NSString *greetingTitle;
@property (readonly, nonatomic) NSString *greetingBody;
@property (readonly, nonatomic) NSURL *greetingImageURL;

@property (readonly, nonatomic) NSString *statusBody;

@property (readonly, nonatomic) NSString *contextMessageBody;

@property (readonly, nonatomic) NSString *HTTPErrorBody;
@property (readonly, nonatomic) NSString *networkErrorBody;

@property (readonly, nonatomic) BOOL profileRequested;
@property (readonly, nonatomic) BOOL profileRequired;

@property (readonly, nonatomic) NSString *personName;
@property (readonly, nonatomic) NSString *personEmailAddress;

@property (readonly, nonatomic) NSString *profileInitialTitle;
@property (readonly, nonatomic) NSString *profileInitialNamePlaceholder;
@property (readonly, nonatomic) NSString *profileInitialEmailPlaceholder;
@property (readonly, nonatomic) NSString *profileInitialSkipButtonTitle;
@property (readonly, nonatomic) NSString *profileInitialSaveButtonTitle;
@property (readonly, nonatomic) NSString *profileInitialEmailExplanation;

@property (readonly, nonatomic) NSString *profileEditTitle;
@property (readonly, nonatomic) NSString *profileEditNamePlaceholder;
@property (readonly, nonatomic) NSString *profileEditEmailPlaceholder;
@property (readonly, nonatomic) NSString *profileEditSkipButtonTitle;
@property (readonly, nonatomic) NSString *profileEditSaveButtonTitle;

@property (readonly, nonatomic) BOOL networkIsReachable;

@property (assign, nonatomic) BOOL didSkipProfile;
@property (strong, nullable, nonatomic) NSString *draftMessage;

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction messageManager:(ApptentiveMessageManager *)messageManager;
- (void)start;
- (void)stop;

- (BOOL)hasNonContextMessages;

- (NSInteger)numberOfMessageGroups;
- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex;
- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)titleForHeaderInSection:(NSInteger)index;
- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldShowDateForMessageGroupAtIndex:(NSInteger)index;
- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath;
- (nullable NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath;
- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath;

- (void)sendMessage:(NSString *)message withAttachments:(NSArray *)attachments;
- (void)setPersonName:(NSString *)name emailAddress:(NSString *)emailAddress;

- (NSInteger)numberOfAttachmentsForMessageAtIndex:(NSInteger)index;
- (BOOL)shouldUsePlaceholderForAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)canPreviewAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)extensionForAttachmentAtIndexPath:(NSIndexPath *)indexPath;			   // Returns nil if thumbnail is present, file extension if not
- (UIImage *)imageForAttachmentAtIndexPath:(NSIndexPath *)indexPath size:(CGSize)size; // Returns thumbnail if present, generic file icon if not
- (void)downloadAttachmentAtIndexPath:(NSIndexPath *)indexPath;
- (id<QLPreviewControllerDataSource>)previewDataSourceAtIndex:(NSInteger)index;

@property (readonly, nonatomic) BOOL lastMessageIsReply;
@property (readonly, nonatomic) ApptentiveMessageState lastUserMessageState;

@end

@protocol ApptentiveMessageCenterViewModelDelegate <NSObject, NSFetchedResultsControllerDelegate>
@optional

- (void)viewModelWillChangeContent:(ApptentiveMessageCenterViewModel *)viewModel;
- (void)viewModelDidChangeContent:(ApptentiveMessageCenterViewModel *)viewModel;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didInsertMessageAtIndex:(NSInteger)index;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didUpdateMessageAtIndex:(NSInteger)index;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didDeleteMessageAtIndex:(NSInteger)index;

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel attachmentDownloadAtIndexPath:(NSIndexPath *)indexPath didProgress:(float)progress;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didFailToLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error;
- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel messageProgressDidChange:(float)progress;

@end

NS_ASSUME_NONNULL_END
