//
//  ATMessageCenterV7ViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterV7ViewController.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATMessageCenterMetrics.h"
#import "ATUtilities.h"
#import "UIImage+ATImageEffects.h"

@interface ATMessageCenterV7ViewController ()
- (void)scrollToBottomOfCollectionView;
@end

@implementation ATMessageCenterV7ViewController {
	BOOL firstLoad;
	NSDateFormatter *messageDateFormatter;
	
	NSMutableArray *fetchedObjectChanges;
	NSMutableArray *fetchedSectionChanges;
}
@synthesize collectionView;

- (id)init {
    self = [super initWithNibName:@"ATMessageCenterV7ViewController" bundle:[ATConnect resourceBundle]];
    if (self) {
		fetchedObjectChanges = [[NSMutableArray alloc] init];
		fetchedSectionChanges = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
	UIImage *blurred = [self blurredBackgroundScreenshot];
	[self.backgroundImageView setImage:blurred];
	
	UINib *automatedCellNib = [UINib nibWithNibName:@"ATAutomatedMessageCellV7" bundle:[ATConnect resourceBundle]];
	[self.collectionView registerNib:automatedCellNib forCellWithReuseIdentifier:@"ATAutomatedMessageCellV7"];
	[self.collectionView reloadData];
	
	messageDateFormatter = [[NSDateFormatter alloc] init];
	messageDateFormatter.dateStyle = NSDateFormatterMediumStyle;
	messageDateFormatter.timeStyle = NSDateFormatterShortStyle;
	
	firstLoad = YES;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[self relayoutSubviews];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[[ATBackend sharedBackend] messageCenterLeftForeground];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[messageDateFormatter release], messageDateFormatter = nil;
	collectionView.delegate = nil;
	[collectionView release], collectionView = nil;
	[fetchedObjectChanges release], fetchedObjectChanges = nil;
	[fetchedSectionChanges release], fetchedSectionChanges = nil;
	[_backgroundImageView release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setCollectionView:nil];
	[self setContainerView:nil];
	[self setInputContainerView:nil];
	[self setBackgroundImageView:nil];
	[super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidHideNotification object:nil];
	if (self.dismissalDelegate && [self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
		[self.dismissalDelegate messageCenterDidDismiss:self];
	}
}

- (void)scrollToBottom {
	[self scrollToBottomOfCollectionView];
}

- (void)relayoutSubviews {
	CGFloat viewHeight = self.view.bounds.size.height;
	
	CGRect composerFrame = self.inputContainerView.frame;
	CGRect collectionFrame = self.collectionView.frame;
	CGRect containerFrame = self.containerView.frame;
	
	composerFrame.origin.y = viewHeight - self.inputContainerView.frame.size.height;
	
	if (!CGRectEqualToRect(CGRectZero, self.currentKeyboardFrameInView)) {
		CGFloat bottomOffset = viewHeight - composerFrame.size.height;
		CGFloat keyboardOffset = self.currentKeyboardFrameInView.origin.y - composerFrame.size.height;
		composerFrame.origin.y = MIN(bottomOffset, keyboardOffset);
	}
	
	collectionFrame.origin.y = 0;
	collectionFrame.size.height = composerFrame.origin.y;
	containerFrame.size.height = collectionFrame.size.height + composerFrame.size.height;
	
	collectionView.frame = collectionFrame;
	self.inputContainerView.frame = composerFrame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self relayoutSubviews];
	
	CGRect containerFrame = self.containerView.frame;
	containerFrame.size.height = self.collectionView.frame.size.height + self.inputContainerView.frame.size.height;
	self.containerView.frame = containerFrame;
	[self.containerView setNeedsLayout];
	[self relayoutSubviews];
}

#pragma mark Private

- (void)scrollToBottomOfCollectionView {
	if ([self.collectionView numberOfSections] > 0) {
		NSInteger rowCount = [self.collectionView numberOfItemsInSection:0];
		if (rowCount > 0) {
			NSUInteger row = rowCount - 1;
			NSIndexPath *path = [NSIndexPath indexPathForItem:row inSection:0];
			[self.collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
		}
	}
}

- (UIImage *)blurredBackgroundScreenshot {
	UIImage *screenshot = [ATUtilities imageByTakingScreenshotIncludingBlankStatusBarArea:YES excludingWindow:self.view.window];
	UIColor *tintColor = [UIColor colorWithWhite:0 alpha:0.1];
	UIImage *blurred = [screenshot at_applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:3.8 maskImage:nil];
	UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
	blurred = [ATUtilities imageByRotatingImage:blurred toInterfaceOrientation:interfaceOrientation];
	
	return blurred;
}

#pragma mark UICollectionViewDelegate

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = [[[self dataSource].fetchedMessagesController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)aCollectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ATAutomatedMessageCellV7" forIndexPath:indexPath];
}


#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		if ([fetchedSectionChanges count]) {
			[self.collectionView performBatchUpdates:^{
				for (NSDictionary *sectionChange in fetchedSectionChanges) {
					[sectionChange enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
						NSFetchedResultsChangeType changeType = (NSFetchedResultsChangeType)[(NSNumber *)key unsignedIntegerValue];
						NSUInteger sectionIndex = [(NSNumber *)obj unsignedIntegerValue];
						switch (changeType) {
							case NSFetchedResultsChangeInsert:
								[self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
								break;
							case NSFetchedResultsChangeDelete:
								[self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
								break;
							case NSFetchedResultsChangeUpdate:
							default:
								break;
						}
					}];
				}
			} completion:^(BOOL finished) {
				[self scrollToBottomOfCollectionView];
			}];
		} else if ([fetchedObjectChanges count]) {
			[self.collectionView performBatchUpdates:^{
				for (NSDictionary *objectChange in fetchedObjectChanges) {
					[objectChange enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
						NSFetchedResultsChangeType changeType = (NSFetchedResultsChangeType)[(NSNumber *)key unsignedIntegerValue];
						if (changeType == NSFetchedResultsChangeMove) {
							NSArray *array = (NSArray *)obj;
							NSIndexPath *indexPath = array[0];
							NSIndexPath *newIndexPath = array[1];
							[self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
						} else {
							NSArray *indexPaths = @[obj];
							switch (changeType) {
								case NSFetchedResultsChangeInsert:
									[self.collectionView insertItemsAtIndexPaths:indexPaths];
									break;
								case NSFetchedResultsChangeDelete:
									[self.collectionView deleteItemsAtIndexPaths:indexPaths];
									break;
								case NSFetchedResultsChangeUpdate:
									[self.collectionView reloadItemsAtIndexPaths:indexPaths];
									break;
								default:
									break;
							}
						}
					}];
				}
			} completion:^(BOOL finished) {
				[self scrollToBottomOfCollectionView];
			}];
		}
		[fetchedObjectChanges removeAllObjects];
		[fetchedSectionChanges removeAllObjects];
	}
	@catch (NSException *exception) {
		ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	[fetchedSectionChanges addObject:@{@(type): @(sectionIndex)}];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[fetchedObjectChanges addObject:@{@(type): newIndexPath}];
			break;
		case NSFetchedResultsChangeDelete:
			[fetchedObjectChanges addObject:@{@(type): indexPath}];
			break;
		case NSFetchedResultsChangeMove:
			[fetchedObjectChanges addObject:@{@(type): @[indexPath, newIndexPath]}];
			break;
		case NSFetchedResultsChangeUpdate:
			[fetchedObjectChanges addObject:@{@(type): indexPath}];
			break;
		default:
			break;
	}
}
@end
