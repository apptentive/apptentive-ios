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

@interface ATMessageCenterDataSource () <NSFetchedResultsControllerDelegate>

@end

@implementation ATMessageCenterDataSource {
	NSFetchedResultsController *fetchedMessagesController;
}
@synthesize delegate;

- (id)initWithDelegate:(NSObject<ATMessageCenterDataSourceDelegate> *)aDelegate {
	if ((self = [super init])) {
		delegate = aDelegate;
	}
	return self;
}

- (void)dealloc {
	fetchedMessagesController.delegate = nil;
	[fetchedMessagesController release], fetchedMessagesController = nil;
	delegate = nil;
	[super dealloc];
}

- (NSFetchedResultsController *)fetchedMessagesController {
	@synchronized(self) {
		if (!fetchedMessagesController) {
			[NSFetchedResultsController deleteCacheWithName:@"at-messages-cache"];
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
			[request setFetchBatchSize:20];
			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationTime" ascending:YES];
			[request setSortDescriptors:@[sortDescriptor]];
			[sortDescriptor release], sortDescriptor = nil;
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"creationTime != %d AND hidden != %@", 0, @YES];
			[request setPredicate:predicate];
			
			NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-messages-cache"];
			newController.delegate = self;
			fetchedMessagesController = newController;
			
			[request release], request = nil;
		}
	}
	return fetchedMessagesController;
}


- (void)start {
	[[ATBackend sharedBackend] messageCenterEnteredForeground];
	
	[self markAllMessagesAsRead];
	[ATTextMessage clearComposingMessages];
	
	NSError *error = nil;
	if (![self.fetchedMessagesController performFetch:&error]) {
		ATLogError(@"Got an error loading messages: %@", error);
		//TODO: Handle this error.
	}
	
	[self createIntroMessageIfNecessary];
}

- (void)stop {
	
}

- (void)markAllMessagesAsRead {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"ATAbstractMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
	[request setFetchBatchSize:20];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientCreationTime" ascending:YES];
	[request setSortDescriptors:@[sortDescriptor]];
	[sortDescriptor release], sortDescriptor = nil;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"seenByUser == %d", 0];
	[request setPredicate:predicate];
	
	NSManagedObjectContext *moc = [ATData moc];
	NSError *error = nil;
	NSArray *results = [moc executeFetchRequest:request error:&error];
	if (!results) {
		ATLogError(@"Error executing fetch request: %@", error);
	} else {
		for (ATAbstractMessage *message in results) {
			[message setSeenByUser:@(YES)];
			if (message.apptentiveID != nil && [message.sentByUser boolValue] != YES) {
				[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidReadNotification object:self userInfo:@{ATMessageCenterMessageIDKey:message.apptentiveID}];
			}
		}
		[ATData save];
	}
	[request release], request = nil;
}

- (void)createIntroMessageIfNecessary {
	NSUInteger messageCount = [ATData countEntityNamed:@"ATAbstractMessage" withPredicate:nil];
	if (messageCount == 0) {
		NSString *title = ATLocalizedString(@"Welcome", @"Welcome");
		NSString *body = ATLocalizedString(@"This is our Message Center. If you have questions, suggestions, concerns or just want to get in touch, please send us a message. We love talking with our customers!", @"Placeholder welcome message.");
		[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
	}
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
@end
