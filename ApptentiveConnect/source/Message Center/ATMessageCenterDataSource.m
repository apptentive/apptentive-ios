//
//  ATMessageCenterDataSource.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterDataSource.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATMessageCenterMetrics.h"
#import "ATTextMessage.h"
#import "ATMessageSender.h"

NSString * const ATMessageCenterServerErrorDomain = @"com.apptentive.MessageCenterServerError";
NSString * const ATMessageCenterErrorMessagesKey = @"com.apptentive.MessageCenterErrorMessages";

@interface ATMessageCenterDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedMessagesController;
@property (nonatomic, readonly) ATAbstractMessage *lastUserMessage;

@end

@implementation ATMessageCenterDataSource

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
		_dateFormatter = [[NSDateFormatter alloc] init];
	}
	return self;
}

- (void)dealloc {
	self.fetchedMessagesController.delegate = nil;
}

- (NSFetchedResultsController *)fetchedMessagesController {
	@synchronized(self) {
		if (!_fetchedMessagesController) {
			[NSFetchedResultsController deleteCacheWithName:@"at-messages-cache"];
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
			[request setFetchBatchSize:20];
			
			NSSortDescriptor *creationTimeSort = [[NSSortDescriptor alloc] initWithKey:@"creationTime" ascending:YES];
			NSSortDescriptor *clientCreationTimeSort = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
			[request setSortDescriptors:@[creationTimeSort, clientCreationTimeSort]];
			
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
	
	[ATTextMessage clearComposingMessages];
	
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
		return (![[self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] isKindOfClass:[ATAutomatedMessage class]]);
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
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		return ATMessageCenterMessageTypeContextMessage;
	} else if (message.sentByUser.boolValue) {
		return ATMessageCenterMessageTypeMessage;
	} else {
		return ATMessageCenterMessageTypeReply;
	}
}

- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATTextMessage class]]) {
		return ((ATTextMessage *)message).body;
	} else {
		return nil;
	}
}

- (NSDate *)dateOfMessageGroupAtIndex:(NSInteger)index {
	if ([self numberOfMessagesInGroup:index] > 0) {
		ATAbstractMessage *message = [self messageAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];
		double creationTime = message.creationTime.doubleValue;
		double clientCreationTime = message.clientCreationTime.doubleValue;
		
		BOOL distantFutureCreationTime = (creationTime > clientCreationTime + 365 * 24 * 60 * 60);
		
		return [NSDate dateWithTimeIntervalSince1970:distantFutureCreationTime ? clientCreationTime : creationTime];
	} else {
		return nil;
	}
}

- (ATMessageCenterMessageStatus)statusOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	
	if (message.sentByUser.boolValue) {
		ATPendingMessageState messageState = message.pendingState.integerValue;
		
		if (messageState == ATPendingMessageStateError) {
			return ATMessageCenterMessageStatusFailed;
		} else if (message == self.lastUserMessage) {
			if (messageState == ATPendingMessageStateSending) {
				return ATMessageCenterMessageStatusSending;
			} else if (messageState == ATPendingMessageStateConfirmed) {
				return ATMessageCenterMessageStatusSent;
			}
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
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	return message.sender.name;
}

- (NSURL *)imageURLOfSenderAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	if (message.sender.profilePhotoURL.length) {
		return [NSURL URLWithString:message.sender.profilePhotoURL];
	} else {
		return nil;
	}
}

- (void)markAsReadMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	
	[message markAsRead];
}

- (BOOL)lastMessageIsReply {
	id<NSFetchedResultsSectionInfo> section = self.fetchedMessagesController.sections.lastObject;
	ATAbstractMessage *lastMessage = section.objects.lastObject;
	
	return lastMessage.sentByUser.boolValue == NO;
}

- (ATPendingMessageState)lastUserMessageState {
	return self.lastUserMessage.pendingState.integerValue;
}

- (NSIndexPath *)lastUserMessageIndexPath {
	return [self.fetchedMessagesController indexPathForObject:self.lastUserMessage];
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

#pragma mark - Private

- (ATAbstractMessage *)messageAtIndexPath:(NSIndexPath *)indexPath {
	return [self.fetchedMessagesController objectAtIndexPath:indexPath];
}

- (ATAbstractMessage *)lastUserMessage {
	for (id<NSFetchedResultsSectionInfo> section in self.fetchedMessagesController.sections.reverseObjectEnumerator) {
		for (ATAbstractMessage *message in section.objects.reverseObjectEnumerator) {
			if (message.sentByUser) {
				return message;
			}
		}
	}
	
	return nil;
}

@end
