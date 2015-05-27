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

@interface ATMessageCenterDataSource () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedMessagesController;

@end

@implementation ATMessageCenterDataSource

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)aDelegate {
	if ((self = [super init])) {
		_delegate = aDelegate;
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
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationTime" ascending:YES];
			[request setSortDescriptors:@[sortDescriptor]];
			sortDescriptor = nil;
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationTime != %d AND hidden != %@", 0, @YES];
			[request setPredicate:predicate];
			
			// For now, group each message into its own section.
			// In the future, we'll save an attribute that coalesces
			// closely-grouped (in time) messages into a single section.
			NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:@"creationTime" cacheName:@"at-messages-cache"];
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
	
}

#pragma mark - Message center view controller support

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
	return message.sentByUser.boolValue ? ATMessageCenterMessageTypeMessage : ATMessageCenterMessageTypeReply;
}

- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATTextMessage class]]) {
		return ((ATTextMessage *)message).body;
	} else {
		return nil;
	}
}

- (NSDate *)dateOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	return [NSDate dateWithTimeIntervalSince1970:[self messageAtIndexPath:indexPath].creationTime.doubleValue];
}

- (NSString *)senderOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = [self messageAtIndexPath:indexPath];
	return message.sender.name;
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

@end
