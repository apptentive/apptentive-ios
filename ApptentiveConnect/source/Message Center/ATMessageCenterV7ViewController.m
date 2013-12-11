//
//  ATMessageCenterV7ViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 11/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterV7ViewController.h"

#import "ATAutomatedMessage.h"
#import "ATAutomatedMessageCellV7.h"
#import "ATBackend.h"
#import "ATBaseMessageCellV7.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATFileMessage.h"
#import "ATFileMessageUserCellV7.h"
#import "ATLog.h"
#import "ATMessageCenterMetrics.h"
#import "ATTextMessage.h"
#import "ATTextMessageDevCellV7.h"
#import "ATTextMessageUserCellV7.h"
#import "ATUtilities.h"
#import "UIImage+ATImageEffects.h"

typedef enum {
	ATMessageCellTypeUnknown,
	ATMessageCellTypeAutomated,
	ATMessageCellTypeText,
	ATMessageCellTypeFile
} ATMessageCellType;

static NSString *const ATAutomatedMessageCellV7Identifier = @"ATAutomatedMessageCellV7";
static NSString *const ATTextMessageDevCellV7Identifier = @"ATTextMessageDevCellV7";
static NSString *const ATTextMessageUserCellV7Identifier = @"ATTextMessageUserCellV7";
static NSString *const ATFileMessageUserCellV7Identifier = @"ATFileMessageUserCellV7";

@interface ATMessageCenterV7ViewController ()
- (void)scrollToBottomOfCollectionView;
@end

@implementation ATMessageCenterV7ViewController {
	BOOL firstLoad;
	NSDateFormatter *messageDateFormatter;
	
	NSMutableArray *fetchedObjectChanges;
	NSMutableArray *fetchedSectionChanges;
	
	ATAutomatedMessageCellV7 *sizingAutomatedCell;
	ATTextMessageDevCellV7 *sizingDevTextCell;
	ATTextMessageUserCellV7 *sizingUserTextCell;
	ATFileMessageUserCellV7 *sizingUserFileCell;
	
	CGFloat sizingAutomatedCellHorizontalPadding;
	CGFloat sizingDevTextCellHorizontalPadding;
	CGFloat sizingUserTextCellHorizontalPadding;
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
	UINib *devTextCellNib = [UINib nibWithNibName:@"ATTextMessageDevCellV7" bundle:[ATConnect resourceBundle]];
	UINib *userTextCellNib = [UINib nibWithNibName:@"ATTextMessageUserCellV7" bundle:[ATConnect resourceBundle]];
	UINib *userFileCellNib = [UINib nibWithNibName:@"ATFileMessageUserCellV7" bundle:[ATConnect resourceBundle]];
	sizingAutomatedCell = [[[automatedCellNib instantiateWithOwner:self options:nil] objectAtIndex:0] retain];
	sizingDevTextCell = [[[devTextCellNib instantiateWithOwner:self options:nil] objectAtIndex:0] retain];
	sizingUserTextCell = [[[userTextCellNib instantiateWithOwner:self options:nil] objectAtIndex:0] retain];
	sizingUserFileCell = [[[userFileCellNib instantiateWithOwner:self options:nil] objectAtIndex:0] retain];
	
	sizingAutomatedCellHorizontalPadding = CGRectGetWidth(sizingAutomatedCell.bounds) - CGRectGetWidth(sizingAutomatedCell.messageLabel.bounds);
	sizingDevTextCellHorizontalPadding = CGRectGetWidth(sizingDevTextCell.bounds) - CGRectGetWidth(sizingDevTextCell.messageLabel.bounds);
	sizingUserTextCellHorizontalPadding = CGRectGetWidth(sizingUserTextCell.bounds) - CGRectGetWidth(sizingUserTextCell.messageLabel.bounds);
	
	[self.collectionView registerNib:automatedCellNib forCellWithReuseIdentifier:ATAutomatedMessageCellV7Identifier];
	[self.collectionView registerNib:devTextCellNib forCellWithReuseIdentifier:ATTextMessageDevCellV7Identifier];
	[self.collectionView registerNib:userTextCellNib forCellWithReuseIdentifier:ATTextMessageUserCellV7Identifier];
	[self.collectionView registerNib:userFileCellNib forCellWithReuseIdentifier:ATFileMessageUserCellV7Identifier];
	self.collectionView.alwaysBounceVertical = YES;
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
	[sizingAutomatedCell release], sizingAutomatedCell = nil;
	[_flowLayout release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setCollectionView:nil];
	[self setContainerView:nil];
	[self setInputContainerView:nil];
	[self setBackgroundImageView:nil];
	[self setFlowLayout:nil];
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
	self.collectionView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
	UIEdgeInsets inset = self.collectionView.scrollIndicatorInsets;
	inset.top = self.collectionView.contentInset.top;
	self.collectionView.scrollIndicatorInsets = inset;
	
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
	[self.flowLayout invalidateLayout];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self relayoutSubviews];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self relayoutSubviews];
}

#pragma mark Private

- (NSString *)keyForIndexPath:(NSIndexPath *)indexPath {
	return [NSString stringWithFormat:@"item:%d", indexPath.item];
}

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

- (ATMessageCellType)cellTypeForMessage:(ATAbstractMessage *)message {
	ATMessageCellType cellType = ATMessageCellTypeUnknown;
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		cellType = ATMessageCellTypeAutomated;
	} else if ([message isKindOfClass:[ATTextMessage class]]) {
		cellType = ATMessageCellTypeText;
	} else if ([message isKindOfClass:[ATFileMessage class]]) {
		cellType = ATMessageCellTypeFile;
	} else {
		NSAssert(NO, @"Unknown cell type");
	}
	return cellType;
}

- (NSString *)dateForCellAtIndexPath:(NSIndexPath *)indexPath {
	BOOL showDate = NO;
	NSString *dateString = nil;
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	
	if (indexPath.row == 0) {
		showDate = YES;
	} else {
		ATAbstractMessage *previousMessage = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
		if ([message.creationTime doubleValue] - [previousMessage.creationTime doubleValue] > 60 * 5) {
			showDate = YES;
		}
	}
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		showDate = YES;
	}
	
	if (showDate) {
		NSTimeInterval t = (NSTimeInterval)[message.creationTime doubleValue];
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:t];
		dateString = [messageDateFormatter stringFromDate:date];
	}
	return dateString;
}

- (void)configureAutomatedCell:(ATAutomatedMessageCellV7 *)cell forIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	cell.dateLabel.text = [self dateForCellAtIndexPath:indexPath];
	cell.message = (ATAutomatedMessage *)message;
}

- (void)configureDevTextCell:(ATTextMessageDevCellV7 *)cell forIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	cell.dateLabel.text = [self dateForCellAtIndexPath:indexPath];
	cell.message = (ATTextMessage *)message;
}

- (void)configureUserTextCell:(ATTextMessageUserCellV7 *)cell forIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	cell.dateLabel.text = [self dateForCellAtIndexPath:indexPath];
	cell.message = (ATTextMessage *)message;
}

- (CGSize)configureUserFileCell:(ATFileMessageUserCellV7 *)cell forIndexPath:(NSIndexPath *)indexPath {
	ATFileMessage *message = (ATFileMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	cell.dateLabel.text = [self dateForCellAtIndexPath:indexPath];
	[cell setMessage:message];
	UIImage *imageFile = [UIImage imageWithContentsOfFile:[message.fileAttachment fullLocalPath]];
	CGSize thumbnailSize = ATThumbnailSizeOfMaxSize(imageFile.size, CGSizeMake(self.collectionView.bounds.size.width, 320));
	CGSize cellSize = thumbnailSize;
	CGFloat ratio = cellSize.height/cellSize.width;
	if (cellSize.width < self.collectionView.bounds.size.width) {
		cellSize.width = self.collectionView.bounds.size.width;
		cellSize.height = self.collectionView.bounds.size.width/ratio;
	}
	return cellSize;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	CGFloat topOffset = -(self.collectionView.contentInset.top + self.collectionView.contentOffset.y);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCollectionDidScroll object:nil userInfo:@{ATMessageCollectionTopOffsetKey: @(topOffset)}];
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
	ATBaseMessageCellV7 *cell = nil;
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	ATMessageCellType cellType = [self cellTypeForMessage:message];
	
	if (cellType == ATMessageCellTypeAutomated) {
		ATAutomatedMessageCellV7 *c = [self.collectionView dequeueReusableCellWithReuseIdentifier:ATAutomatedMessageCellV7Identifier forIndexPath:indexPath];
		[self configureAutomatedCell:c forIndexPath:indexPath];
		cell = c;
	} else if (cellType == ATMessageCellTypeText && [message.sentByUser boolValue]) {
		ATTextMessageUserCellV7 *c = [self.collectionView dequeueReusableCellWithReuseIdentifier:ATTextMessageUserCellV7Identifier forIndexPath:indexPath];
		[self configureUserTextCell:c forIndexPath:indexPath];
		cell = c;
	} else if (cellType == ATMessageCellTypeText && ![message.sentByUser boolValue]) {
		ATTextMessageDevCellV7 *c = [self.collectionView dequeueReusableCellWithReuseIdentifier:ATTextMessageDevCellV7Identifier forIndexPath:indexPath];
		[self configureDevTextCell:c forIndexPath:indexPath];
		cell = c;
	} else if (cellType == ATMessageCellTypeFile && [message.sentByUser boolValue]) {
		ATFileMessageUserCellV7 *c = [self.collectionView dequeueReusableCellWithReuseIdentifier:ATFileMessageUserCellV7Identifier forIndexPath:indexPath];
		[self configureUserFileCell:c forIndexPath:indexPath];
		cell = c;
	} else {
		cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:ATAutomatedMessageCellV7Identifier forIndexPath:indexPath];
	}
	
	[cell setNeedsUpdateConstraints];
	return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewCell *cell = nil;
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	ATMessageCellType cellType = [self cellTypeForMessage:message];
	
	if (cellType == ATMessageCellTypeAutomated) {
		[self configureAutomatedCell:sizingAutomatedCell forIndexPath:indexPath];
		cell = sizingAutomatedCell;
		sizingAutomatedCell.messageLabel.preferredMaxLayoutWidth = self.collectionView.bounds.size.width - sizingAutomatedCellHorizontalPadding;
		
		CGSize s = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
		s.width = self.collectionView.bounds.size.width;
		
		return s;
	} else if (cellType == ATMessageCellTypeText && [message.sentByUser boolValue]) {
		sizingUserTextCell.messageLabel.preferredMaxLayoutWidth = self.collectionView.bounds.size.width - sizingUserTextCellHorizontalPadding;
		
		[self configureUserTextCell:sizingUserTextCell forIndexPath:indexPath];
		cell = sizingUserTextCell;
		CGSize s = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
		s.width = self.collectionView.bounds.size.width;
		return s;
	} else if (cellType == ATMessageCellTypeText && ![message.sentByUser boolValue]) {
		sizingDevTextCell.messageLabel.preferredMaxLayoutWidth = self.collectionView.bounds.size.width - sizingDevTextCellHorizontalPadding;
		
		[self configureDevTextCell:sizingDevTextCell forIndexPath:indexPath];
		cell = sizingDevTextCell;
		CGSize s = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
		s.width = self.collectionView.bounds.size.width;
		return s;
	} else if (cellType == ATMessageCellTypeFile && [message.sentByUser boolValue]) {
		[self configureUserFileCell:sizingUserFileCell forIndexPath:indexPath];
		cell = sizingUserFileCell;
		CGSize s = [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
		s.width = self.collectionView.bounds.size.width;
		return s;
	} else {
		return CGSizeMake(self.collectionView.bounds.size.width, 40);
	}
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
		ATLogError(@"Caught exception: %@: %@", [exception name], [exception description]);
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
