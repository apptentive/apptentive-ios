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
			
			NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-messages-cache"];
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
	
	[self createIntroMessageIfNecessary];
}

- (void)stop {
	
}

- (void)createIntroMessageIfNecessary {
	NSUInteger messageCount = [ATData countEntityNamed:@"ATAbstractMessage" withPredicate:nil];
	if (messageCount == 0) {
		NSString *title = ATLocalizedString(@"Welcome", @"Welcome");
		NSString *body = ATLocalizedString(@"This is our Message Center. If you have questions, suggestions, concerns or just want to get in touch, please send us a message. We love talking with our customers!", @"Placeholder welcome message.");
		[[ATBackend sharedBackend] sendAutomatedMessageWithTitle:title body:body];
	}
}

#warning TODO: Actually implement these

- (NSInteger)numberOfMessageGroups {
	return 2;
}

- (NSInteger)numberOfMessagesInGroup:(NSInteger)groupIndex {
	return 1;
}

- (ATMessageCenterMessageType)cellTypeAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath.section % 2 == 0) ? ATMessageCenterMessageTypeMessage : ATMessageCenterMessageTypeReply;
}

- (NSString *)textOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section % 2 == 0) {
		return @"Yeah, I like the app overall, but it just closed without saving. can you help?";
	} else {
		return @"Hey Andrew. I can help you with that. We’ve had a couple reports of this happening on older versions of the app.\n\nIf you open the App Store, and click the “Updates” tab, you should see that our latest version is 4.3.5. From there, you can tap “Update All” - many customers report this helping them.\n\nIn the mean time, could you please describe what it was that caused the bug in the first place? What part of the app were you in, what did you tap, and what were you trying to accomplish?";;
	}
}

- (NSDate *)dateOfMessageAtIndexPath:(NSIndexPath *)indexPath {
	return [NSDate date];
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
