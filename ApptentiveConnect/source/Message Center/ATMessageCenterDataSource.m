//
//  ATMessageCenterDataSource.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterDataSource.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATMessageSender.h"
#import "ATAttachmentCell.h"

NSString * const ATMessageCenterServerErrorDomain = @"com.apptentive.MessageCenterServerError";
NSString * const ATMessageCenterErrorMessagesKey = @"com.apptentive.MessageCenterErrorMessages";

@interface ATMessageCenterDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedMessagesController;
@property (nonatomic, readonly) ATMessage *lastUserMessage;
@property (nonatomic, readonly) NSURLSession *attachmentDownloadSession;
@property (nonatomic, readonly) NSMutableDictionary<NSValue *, NSIndexPath *> *taskIndexPaths;

@end

@implementation ATMessageCenterDataSource

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
		_dateFormatter = [[NSDateFormatter alloc] init];

		_attachmentDownloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
		_taskIndexPaths = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc {
	// TODO: get resume data from cancelled downloads and use it
	[self.attachmentDownloadSession invalidateAndCancel];

	self.fetchedMessagesController.delegate = nil;
}

- (NSFetchedResultsController *)fetchedMessagesController {
	@synchronized(self) {
		if (!_fetchedMessagesController) {
			[NSFetchedResultsController deleteCacheWithName:@"at-messages-cache"];
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
			[request setFetchBatchSize:20];
			
			//NSSortDescriptor *creationTimeSort = [[NSSortDescriptor alloc] initWithKey:@"creationTime" ascending:YES];
			NSSortDescriptor *clientCreationTimeSort = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
			[request setSortDescriptors:@[clientCreationTimeSort]];
			
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationTime != %d AND clientCreationTime != %d AND hidden != %@", 0, 0, @YES];
			[request setPredicate:predicate];
			
			// For now, group each message into its own section.
			// In the future, we'll save an attribute that coalesces
			// closely-grouped (in time) messages into a single section.
			NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:@"clientCreationTime" cacheName:@"at-messages-cache"];
			newController.delegate = self;
			_fetchedMessagesController = newController;
			
			request = nil;
		}
	}
	return _fetchedMessagesController;
}

- (void)start {
	[[ATBackend sharedBackend] messageCenterEnteredForeground];
	[ATMessage clearComposingMessages];
	
	NSError *error = nil;
	if (![self.fetchedMessagesController performFetch:&error]) {
		ATLogError(@"Got an error loading messages: %@", error);
		//TODO: Handle this error.
	}
}

- (void)stop {
	[[ATBackend sharedBackend] messageCenterLeftForeground];
}

#pragma mark - Message center view controller support

- (BOOL)hasNonContextMessages {
	if (self.numberOfMessageGroups == 0 || [self numberOfMessagesInGroup:0] == 0) {
		return NO;
	} else if (self.numberOfMessageGroups == 1) {
		return (![self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].automated.boolValue);
	} else {
		return YES;
	}
}

- (NSInteger)numberOfMessageGroups {
	return self.fetchedMessagesController.sections.count;
}

- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex {
	if ([[self.fetchedMessagesController sections] count] > 0) {
		return [[[self.fetchedMessagesController sections] objectAtIndex:groupIndex] numberOfObjects];
	} else
		return 0;
}

- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = [self messageAtIndexPath:indexPath];
	
	if (message.automated.boolValue) {
		return ATMessageCenterMessageTypeContextMessage;
	} else if (message.sentByUser.boolValue) {
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

- (NSDate *)dateOfMessageGroupAtIndex:(NSInteger)index {
	if ([self numberOfMessagesInGroup:index] > 0) {
		ATMessage *message = [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];
		
		return [NSDate dateWithTimeIntervalSince1970:[message.creationTimeForSections doubleValue]];
	} else {
		return nil;
	}
}

- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = [self messageAtIndexPath:indexPath];
	
	if (message.sentByUser.boolValue) {
		ATPendingMessageState messageState = message.pendingState.integerValue;
		
		if (messageState == ATPendingMessageStateError) {
			return ATMessageCenterMessageStatusFailed;
		} else if (messageState == ATPendingMessageStateSending) {
			return ATMessageCenterMessageStatusSending;
		} else if (message == self.lastUserMessage && messageState == ATPendingMessageStateConfirmed) {
			return ATMessageCenterMessageStatusSent;
		}
	}

	return ATMessageCenterMessageStatusHidden;
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
	ATMessage *message = [self messageAtIndexPath:indexPath];
	return message.sender.name;
}

- (NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = [self messageAtIndexPath:indexPath];
	if (message.sender.profilePhotoURL.length) {
		return [NSURL URLWithString:message.sender.profilePhotoURL];
	} else {
		return nil;
	}
}

- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = [self messageAtIndexPath:indexPath];
	
	[message markAsRead];
}

- (BOOL)lastMessageIsReply {
	id<NSFetchedResultsSectionInfo> section = self.fetchedMessagesController.sections.lastObject;
	ATMessage *lastMessage = section.objects.lastObject;
	
	return lastMessage.sentByUser.boolValue == NO;
}

- (ATPendingMessageState)lastUserMessageState {
	return self.lastUserMessage.pendingState.integerValue;
}

- (NSIndexPath *)lastUserMessageIndexPath {
	return [self.fetchedMessagesController indexPathForObject:self.lastUserMessage];
}

#pragma mark Attachments

- (NSInteger)numberOfAttachmentsForMessageAtIndex:(NSInteger)index {
	return [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]].attachments.count;
}

- (BOOL)shouldUsePlaceholderForAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ATFileAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	return attachment.localPath == nil;
}

- (UIImage *)imageForAttachmentAtIndexPath:(NSIndexPath *)indexPath size:(CGSize)size {
	ATFileAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	if (attachment.localPath) {
		return [attachment thumbnailOfSize:size];
	} else if (attachment.remoteThumbnailURL) {
		// kick off download of thumbnail
	}

	// return generic image attachment icon
	return [[ATBackend imageNamed:@"at_document"] resizableImageWithCapInsets:UIEdgeInsetsMake(9.0, 2.0, 2.0, 9.0)];
}

- (NSString *)extensionForAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ATFileAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];

	CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(attachment.mimeType), NULL);
	NSString *extension = (__bridge NSString *)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);

	return extension;
}

- (void)downloadAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	if ([self.taskIndexPaths.allValues containsObject:indexPath]) {
		return;
	}

	ATFileAttachment *attachment = [self fileAttachmentAtIndexPath:indexPath];
	if (attachment.localPath != nil || !attachment.remoteURL) {
		ATLogError(@"Attempting to download attachment with missing or invalid remote URL");
		return;
	}

	NSURLRequest *request = [NSURLRequest requestWithURL:attachment.remoteURL];
	NSURLSessionDownloadTask *task = [self.attachmentDownloadSession downloadTaskWithRequest:request];

	[self.delegate messageCenterDataSource:self attachmentDownloadAtIndexPath:indexPath didProgress:0];

	[self setIndexPath:indexPath forTask:task];
	[task resume];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	if ([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
		[self.delegate controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	if ([self.delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
		[self.delegate controller:controller didChangeSection:sectionInfo atIndex:sectionIndex forChangeType:type];
	}
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
		[self.delegate controllerWillChangeContent:controller];
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
		[self.delegate controllerDidChangeContent:controller];
	}
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName {
	if ([self.delegate respondsToSelector:@selector(controller:sectionIndexTitleForSectionName:)]) {
		return [self.delegate controller:controller sectionIndexTitleForSectionName:sectionName];
	} else {
		// Default implementation.
		if (!sectionName || [sectionName length] == 0) {
			return @"";
		}
		NSString *firstLetter = [sectionName substringWithRange:NSMakeRange(0, 1)];
		return [firstLetter uppercaseStringWithLocale:[NSLocale currentLocale]];
	}
}

#pragma mark - URL session delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
	NSIndexPath *attachmentIndexPath = [self indexPathForTask:downloadTask];
	[self removeTask:downloadTask];

	ATFileAttachment *attachment = [self fileAttachmentAtIndexPath:attachmentIndexPath];
	// -beginMoveToStorageFrom: must be called on this (background) thread.
	NSURL *finalLocation = [attachment beginMoveToStorageFrom:location];

	dispatch_async(dispatch_get_main_queue(), ^{
		// -completeMoveToStorageFor: must be called on main thread.
		[attachment completeMoveToStorageFor:finalLocation];
		[self.delegate messageCenterDataSource:self didLoadAttachmentThumbnailAtIndexPath:attachmentIndexPath];
	});
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	NSIndexPath *attachmentIndexPath = [self indexPathForTask:downloadTask];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate messageCenterDataSource:self attachmentDownloadAtIndexPath:attachmentIndexPath didProgress:(double)totalBytesWritten / (double)totalBytesExpectedToWrite];
	});
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	NSIndexPath *attachmentIndexPath = [self indexPathForTask:task];
	[self removeTask:task];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate messageCenterDataSource:self didFailToLoadAttachmentThumbnailAtIndexPath:attachmentIndexPath error:error];
	});
}

# pragma mark - Misc

- (void)removeUnsentContextMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATMessage" withPredicate:fetchPredicate];
	}
}

#pragma mark - Private

- (NSIndexPath *)indexPathForTask:(NSURLSessionTask *)task {
	return [self.taskIndexPaths objectForKey:[NSValue valueWithNonretainedObject:task]];
}

- (void)setIndexPath:(NSIndexPath *)indexPath forTask:(NSURLSessionTask *)task {
	[self.taskIndexPaths setObject:indexPath forKey:[NSValue valueWithNonretainedObject:task]];
}

- (void)removeTask:(NSURLSessionTask *)task {
	[self.taskIndexPaths removeObjectForKey:[NSValue valueWithNonretainedObject:task]];
}

// indexPath.section refers to the message index (table view section), indexPath.row refers to the attachment index.
- (ATFileAttachment *)fileAttachmentAtIndexPath:(NSIndexPath *)indexPath {
	ATMessage *message = [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	return [message.attachments objectAtIndex:indexPath.row];
}

- (ATMessage *)messageAtIndexPath:(NSIndexPath *)indexPath {
	return [self.fetchedMessagesController objectAtIndexPath:indexPath];
}

- (ATMessage *)lastUserMessage {
	for (id<NSFetchedResultsSectionInfo> section in self.fetchedMessagesController.sections.reverseObjectEnumerator) {
		for (ATMessage *message in section.objects.reverseObjectEnumerator) {
			if (message.sentByUser) {
				return message;
			}
		}
	}
	
	return nil;
}

@end
