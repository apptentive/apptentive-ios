//
//  ApptentiveMessageCenterViewModel.m
//  Apptentive
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterViewModel.h"
#import "ApptentiveAttachment.h"
#import "ApptentiveMessageSender.h"

#import "Apptentive.h"
#import "ApptentiveAttachmentCell.h"
#import "ApptentiveBackend.h"
#import "ApptentiveDefines.h"
#import "ApptentiveInteraction.h"
#import "ApptentivePerson.h"
#import "ApptentiveReachability.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveDispatchQueue.h"
#import "ApptentiveGCDDispatchQueue.h"
#import "ApptentiveBackend+Engagement.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const ATMessageCenterServerErrorDomain = @"com.apptentive.MessageCenterServerError";
NSString *const ATMessageCenterErrorMessagesKey = @"com.apptentive.MessageCenterErrorMessages";
NSString *const ATInteractionMessageCenterEventLabelRead = @"read";


@interface ApptentiveMessageCenterViewModel ()

@property (readonly, nullable, nonatomic) ApptentiveMessage *lastUserMessage;
@property (readonly, nonatomic) NSURLSession *attachmentDownloadSession;
@property (readonly, nonatomic) NSMutableDictionary<NSValue *, NSIndexPath *> *taskIndexPaths;
@property (nullable, strong, nonatomic) ApptentiveMessage *contextMessage;

@end


@implementation ApptentiveMessageCenterViewModel

- (instancetype)initWithInteraction:(ApptentiveInteraction *)interaction messageManager:(ApptentiveMessageManager *)messageManager {
	if ((self = [super init])) {
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(interaction);
		APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(messageManager);

		_interaction = interaction;
		_messageManager = messageManager;
		messageManager.delegate = self;

		_dateFormatter = [[NSDateFormatter alloc] init];
		_dateFormatter.dateStyle = NSDateFormatterLongStyle;
		_dateFormatter.timeStyle = NSDateFormatterNoStyle;

		_attachmentDownloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:((ApptentiveGCDDispatchQueue *)self.messageManager.operationQueue).queue];
		_taskIndexPaths = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc {
	ApptentiveAssertTrue(self.messageManager.delegate == self || self.messageManager.delegate == nil, @"Delegate mismatch");
	if (self.messageManager.delegate == self) {
		self.messageManager.delegate = nil;
	}
}

- (void)start {
	[[Apptentive sharedConnection].backend messageCenterEnteredForeground];

	if (self.contextMessageBody) {
		self.contextMessage = [[ApptentiveMessage alloc] initWithBody:self.contextMessageBody attachments:@[] automated:YES customData:nil creationDate:[NSDate date]];
		ApptentiveAssertNotNil(self.contextMessage, @"Context message is nil");

		[self.contextMessage updateWithLocalIdentifier:@"context-message"];

		// Don't trigger table view update
		self.messageManager.delegate = nil;
		[self.messageManager appendMessage:self.contextMessage];
		self.messageManager.delegate = self;
	}
}

- (void)stop {
	if (self.contextMessage) {
		[self.messageManager removeMessage:self.contextMessage];
	}

	[[Apptentive sharedConnection].backend messageCenterLeftForeground];

	// TODO: get resume data from cancelled downloads and use it
	[self.attachmentDownloadSession invalidateAndCancel];
}

#pragma mark - Message center view controller support

- (id<ApptentiveStyle>)styleSheet {
	return Apptentive.shared.style;
}

- (NSString *)title {
	return self.interaction.configuration[@"title"];
}

- (NSString *)branding {
	return self.interaction.configuration[@"branding"];
}

#pragma mark - Composer

- (NSString *)composerTitle {
	return self.interaction.configuration[@"composer"][@"title"];
}

- (NSString *)composerPlaceholderText {
	return self.interaction.configuration[@"composer"][@"hint_text"];
}

- (NSString *)composerSendButtonTitle {
	return self.interaction.configuration[@"composer"][@"send_button"];
}

- (NSString *)composerCloseConfirmBody {
	return self.interaction.configuration[@"composer"][@"close_confirm_body"];
}

- (NSString *)composerCloseDiscardButtonTitle {
	return self.interaction.configuration[@"composer"][@"close_discard_button"];
}

- (NSString *)composerCloseCancelButtonTitle {
	return self.interaction.configuration[@"composer"][@"close_cancel_button"];
}

#pragma mark - Greeting

- (NSString *)greetingTitle {
	return self.interaction.configuration[@"greeting"][@"title"];
}

- (NSString *)greetingBody {
	return self.interaction.configuration[@"greeting"][@"body"];
}

- (NSURL *)greetingImageURL {
	NSString *URLString = self.interaction.configuration[@"greeting"][@"image_url"];

	return (URLString.length > 0) ? [NSURL URLWithString:URLString] : nil;
}

#pragma mark - Status

- (NSString *)statusBody {
	return self.interaction.configuration[@"status"][@"body"];
}

#pragma mark - Context / Automated Message

- (NSString *)contextMessageBody {
	return self.interaction.configuration[@"automated_message"][@"body"];
}

#pragma mark - Error Messages

- (NSString *)HTTPErrorBody {
	return self.interaction.configuration[@"error_messages"][@"http_error_body"];
}

- (NSString *)networkErrorBody {
	return self.interaction.configuration[@"error_messages"][@"network_error_body"];
}

#pragma mark - Profile

- (BOOL)profileRequested {
	return [self.interaction.configuration[@"profile"][@"request"] boolValue];
}

- (BOOL)profileRequired {
	return [self.interaction.configuration[@"profile"][@"require"] boolValue];
}

- (NSString *)personName {
	return Apptentive.shared.personName;
}

- (NSString *)personEmailAddress {
	return Apptentive.shared.personEmailAddress;
}

#pragma mark - Profile (Initial)

- (NSString *)profileInitialTitle {
	return self.interaction.configuration[@"profile"][@"initial"][@"title"];
}

- (NSString *)profileInitialNamePlaceholder {
	return self.interaction.configuration[@"profile"][@"initial"][@"name_hint"];
}

- (NSString *)profileInitialEmailPlaceholder {
	return self.interaction.configuration[@"profile"][@"initial"][@"email_hint"];
}

- (NSString *)profileInitialSkipButtonTitle {
	return self.interaction.configuration[@"profile"][@"initial"][@"skip_button"];
}

- (NSString *)profileInitialSaveButtonTitle {
	return self.interaction.configuration[@"profile"][@"initial"][@"save_button"];
}

- (NSString *)profileInitialEmailExplanation {
	return self.interaction.configuration[@"profile"][@"initial"][@"email_explanation"];
}

#pragma mark - Profile (Edit)

- (NSString *)profileEditTitle {
	return self.interaction.configuration[@"profile"][@"edit"][@"title"];
}

- (NSString *)profileEditNamePlaceholder {
	return self.interaction.configuration[@"profile"][@"edit"][@"name_hint"];
}

- (NSString *)profileEditEmailPlaceholder {
	return self.interaction.configuration[@"profile"][@"edit"][@"email_hint"];
}

- (NSString *)profileEditSkipButtonTitle {
	return self.interaction.configuration[@"profile"][@"edit"][@"skip_button"];
}

- (NSString *)profileEditSaveButtonTitle {
	return self.interaction.configuration[@"profile"][@"edit"][@"save_button"];
}

#pragma mark - Messages

- (BOOL)hasNonContextMessages {
	if (self.numberOfMessageGroups == 0 || [self numberOfMessagesInGroup:0] == 0) {
		return NO;
	} else if (self.numberOfMessageGroups == 1) {
		return (![self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].automated);
	} else {
		return YES;
	}
}

- (NSInteger)numberOfMessageGroups {
	return [self.messageManager numberOfMessages];
}

- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex {
	return 1;
}

- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:indexPath];

	if (message.automated) {
		return ATMessageCenterMessageTypeContextMessage;
	} else if (message.inbound) {
		if (message.attachments.count) {
			return ATMessageCenterMessageTypeCompoundMessage;
		} else {
			return ATMessageCenterMessageTypeMessage;
		}
	} else {
		if (message.attachments.count) {
			return ATMessageCenterMessageTypeCompoundReply;
		} else {
			return ATMessageCenterMessageTypeReply;
		}
	}
}

- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	return [self messageAtIndexPath:indexPath].body;
}

- (NSString *)titleForHeaderInSection:(NSInteger)index {
	return [self.dateFormatter stringFromDate:[self dateOfMessageGroupAtIndex:index]];
}

- (nullable NSDate *)dateOfMessageGroupAtIndex:(NSInteger)index {
	if ([self numberOfMessagesInGroup:index] > 0) {
		ApptentiveMessage *message = [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];

		return message.sentDate;
	} else {
		return nil;
	}
}

- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:indexPath];

	switch (message.state) {
		case ApptentiveMessageStateFailedToSend:
			return ATMessageCenterMessageStatusFailed;
		case ApptentiveMessageStateWaiting:
		case ApptentiveMessageStateSending:
			return ATMessageCenterMessageStatusSending;
		case ApptentiveMessageStateSent:
			if (message == self.lastUserMessage)
				return ATMessageCenterMessageStatusSent;
		default:
			return ATMessageCenterMessageStatusHidden;
	}
}

- (BOOL)shouldShowDateForMessageGroupAtIndex:(NSInteger)index {
	if (index == 0) {
		return YES;
	} else {
		NSDate *previousDate = [self dateOfMessageGroupAtIndex:index - 1];
		NSDate *currentDate = [self dateOfMessageGroupAtIndex:index];

		return ![[self.dateFormatter stringFromDate:previousDate] isEqualToString:[self.dateFormatter stringFromDate:currentDate]];
	}
}

- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:indexPath];
	return message.sender.name;
}

- (nullable NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:indexPath];
	if (message.sender.profilePhotoURL) {
		return message.sender.profilePhotoURL;
	} else {
		return nil;
	}
}

- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:indexPath];

	if (message.identifier && !message.inbound) {
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

		if (message.identifier) {
			[userInfo setObject:message.identifier forKey:@"message_id"];
		}

		[userInfo setObject:@"CompoundMessage" forKey:@"message_type"];

		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelRead fromInteraction:self.interaction fromViewController:nil userInfo:userInfo];
	}

	if (message.state == ApptentiveMessageStateUnread) {
		[self.messageManager.operationQueue dispatchAsync:^{
		  message.state = ApptentiveMessageStateRead;
		  [self.messageManager updateUnreadCount];
		  [self.messageManager saveMessageStore];
		}];
	}
}

- (BOOL)lastMessageIsReply {
	ApptentiveMessage *lastMessage = self.messageManager.messages.lastObject;

	return !lastMessage.inbound;
}

- (ApptentiveMessageState)lastUserMessageState {
	return self.lastUserMessage.state;
}

#pragma mark Attachments

- (NSInteger)numberOfAttachmentsForMessageAtIndex:(NSInteger)index {
	return [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]].attachments.count;
}

- (BOOL)shouldUsePlaceholderForAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	return attachment.filename == nil || !attachment.canCreateThumbnail;
}

- (BOOL)canPreviewAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	return attachment.filename != nil;
}

- (UIImage *)imageForAttachmentAtIndexPath:(NSIndexPath *)indexPath size:(CGSize)size {
	ApptentiveAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];
	attachment.attachmentDirectoryPath = self.messageManager.attachmentDirectoryPath;

	if (attachment.filename) {
		UIImage *thumbnail = [attachment thumbnailOfSize:size];
		if (thumbnail) {
			return thumbnail;
		}
	}

	// return generic image attachment icon
	return [[ApptentiveUtilities imageNamed:@"at_document"] resizableImageWithCapInsets:UIEdgeInsetsMake(9.0, 2.0, 2.0, 9.0)];
}

- (NSString *)extensionForAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	return attachment.extension;
}

- (void)downloadAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.taskIndexPaths.allValues containsObject:indexPath]) {
		return;
	}

	ApptentiveAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];
	attachment.attachmentDirectoryPath = self.messageManager.attachmentDirectoryPath;
	if (attachment.filename != nil || !attachment.remoteURL) {
		ApptentiveLogError(@"Attempting to download attachment with missing or invalid remote URL");
		return;
	}

	NSURLRequest *request = [NSURLRequest requestWithURL:attachment.remoteURL];
	NSURLSessionDownloadTask *task = [self.attachmentDownloadSession downloadTaskWithRequest:request];

	[self.delegate messageCenterViewModel:self attachmentDownloadAtIndexPath:indexPath didProgress:0];

	[self setIndexPath:indexPath forTask:task];
	[task resume];
}

- (id<QLPreviewControllerDataSource>)previewDataSourceAtIndex:(NSInteger)index {
	return [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];
}

#pragma mark - URL session delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	NSIndexPath *attachmentIndexPath = [self indexPathForTask:downloadTask];
	[self removeTask:downloadTask];

	NSURL *finalLocation = [self fileAttachmentAtIndexPath:attachmentIndexPath].permanentLocation;

	// -beginMoveToStorageFrom: must be called on this (background) thread.
	NSError *error;
	if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:finalLocation error:&error]) {
		ApptentiveLogError(@"Unable to move attachment to final location: %@", error);
	}

	dispatch_async(dispatch_get_main_queue(), ^{
	  // -completeMoveToStorageFor: must be called on main thread.
	  [[self fileAttachmentAtIndexPath:attachmentIndexPath] completeMoveToStorageFor:finalLocation];
	  [self.delegate messageCenterViewModel:self didLoadAttachmentThumbnailAtIndexPath:attachmentIndexPath];

	  [self.messageManager.operationQueue dispatchAsync:^{
		[self.messageManager saveMessageStore];
	  }];
	});
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	NSIndexPath *attachmentIndexPath = [self indexPathForTask:downloadTask];

	dispatch_async(dispatch_get_main_queue(), ^{
	  [self.delegate messageCenterViewModel:self attachmentDownloadAtIndexPath:attachmentIndexPath didProgress:(double)totalBytesWritten / (double)totalBytesExpectedToWrite];
	});
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
	if (error == nil) return;

	NSIndexPath *attachmentIndexPath = [self indexPathForTask:task];
	[self removeTask:task];

	dispatch_async(dispatch_get_main_queue(), ^{
	  [self.delegate messageCenterViewModel:self didFailToLoadAttachmentThumbnailAtIndexPath:attachmentIndexPath error:error];
	});
}

#pragma mark - Message Manager delegate

- (void)messageManagerWillBeginUpdates:(ApptentiveMessageManager *)manager {
	[self.delegate viewModelWillChangeContent:self];
}

- (void)messageManagerDidEndUpdates:(ApptentiveMessageManager *)manager {
	[self.delegate viewModelDidChangeContent:self];
}

- (void)messageManager:(ApptentiveMessageManager *)manager didInsertMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index {
	[self.delegate messageCenterViewModel:self didInsertMessageAtIndex:index];
}

- (void)messageManager:(ApptentiveMessageManager *)manager didUpdateMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index {
	[self.delegate messageCenterViewModel:self didUpdateMessageAtIndex:index];
}

- (void)messageManager:(ApptentiveMessageManager *)manager didDeleteMessage:(ApptentiveMessage *)message atIndex:(NSInteger)index {
	[self.delegate messageCenterViewModel:self didDeleteMessageAtIndex:index];
}

- (void)messageManager:(ApptentiveMessageManager *)manager messageSendProgressDidUpdate:(float)progress {
	[self.delegate messageCenterViewModel:self messageProgressDidChange:progress];
}

#pragma mark - Misc

- (void)sendMessage:(NSString *)messageText withAttachments:(NSArray *)attachments {
	if (self.contextMessage) {
		[self.messageManager enqueueMessageForSendingOnBackgroundQueue:self.contextMessage];
		self.contextMessage = nil;
	}

	ApptentiveMessage *message = [[ApptentiveMessage alloc] initWithBody:messageText attachments:attachments automated:NO customData:Apptentive.shared.backend.currentCustomData creationDate:[NSDate date]];

	ApptentiveAssertNotNil(message, @"Message is nil");
	if (message != nil) {
		[self.messageManager sendMessage:message];
	}

	Apptentive.shared.backend.currentCustomData = nil;
}

- (void)setPersonName:(NSString *)name emailAddress:(NSString *)emailAddress {
	Apptentive.shared.personName = name;
	Apptentive.shared.personEmailAddress = emailAddress;
}

- (BOOL)networkIsReachable {
	return Apptentive.shared.backend.networkAvailable;
}

- (BOOL)didSkipProfile {
	return self.messageManager.didSkipProfile;
}

- (void)setDidSkipProfile:(BOOL)didSkipProfile {
	self.messageManager.didSkipProfile = didSkipProfile;
}

- (nullable NSString *)draftMessage {
	return self.messageManager.draftMessage;
}

- (void)setDraftMessage:(nullable NSString *)draftMessage {
	self.messageManager.draftMessage = draftMessage;
}

#pragma mark - Private

- (NSIndexPath *)indexPathForTask:(NSURLSessionTask *)task {
	return [self.taskIndexPaths objectForKey:[NSValue valueWithNonretainedObject:task]];
}

- (void)setIndexPath:(NSIndexPath *)indexPath forTask:(NSURLSessionTask *)task {
	ApptentiveDictionarySetKeyValue(self.taskIndexPaths, [NSValue valueWithNonretainedObject:task], indexPath);
}

- (void)removeTask:(NSURLSessionTask *)task {
	[self.taskIndexPaths removeObjectForKey:[NSValue valueWithNonretainedObject:task]];
}

// indexPath.section refers to the message index (table view section), indexPath.row refers to the attachment index.
- (ApptentiveAttachment *)fileAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveMessage *message = [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	return [message.attachments objectAtIndex:indexPath.row];
}

- (ApptentiveMessage *)messageAtIndexPath:(NSIndexPath *)indexPath {
	return [self.messageManager.messages objectAtIndex:indexPath.section];
}

- (nullable ApptentiveMessage *)lastUserMessage {
	for (ApptentiveMessage *message in self.messageManager.messages.reverseObjectEnumerator) {
		if (message.inbound) {
			return message;
		}
	}

	return nil;
}

@end

NS_ASSUME_NONNULL_END
