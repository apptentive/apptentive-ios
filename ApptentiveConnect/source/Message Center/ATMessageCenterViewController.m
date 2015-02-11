//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "ATMessageCenterViewController.h"

#import "ATBackend.h"
#import "ATConnect.h"
#import "ATConnect_Private.h"
#import "ATData.h"
#import "ATAutomatedMessage.h"
#import "ATFileAttachment.h"
#import "ATFileMessage.h"
#import "ATLog.h"
#import "ATAbstractMessage.h"
#import "ATDefaultMessageCenterTheme.h"
#import "ATMessageCenterCell.h"
#import "ATMessageCenterMetrics.h"
#import "ATMessageSender.h"
#import "ATMessageTask.h"
#import "ATPersonDetailsViewController.h"
#import "ATPersonUpdater.h"
#import "ATTaskQueue.h"
#import "ATTextMessage.h"
#import "ATUtilities.h"

typedef enum {
	ATMessageCellTypeUnknown,
	ATMessageCellTypeAutomated,
	ATMessageCellTypeText,
	ATMessageCellTypeFile
} ATMessageCellType;

#define TextViewPadding 2

@implementation ATMessageCenterViewController {
	BOOL firstLoad;
	NSDateFormatter *messageDateFormatter;
}
@synthesize tableView, automatedCell;
@synthesize userCell, developerCell, userFileMessageCell;

- (id)init {
	self = [super initWithNibName:@"ATMessageCenterViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self.tableView reloadData];
	
	messageDateFormatter = [[NSDateFormatter alloc] init];
	messageDateFormatter.dateStyle = NSDateFormatterMediumStyle;
	messageDateFormatter.timeStyle = NSDateFormatterShortStyle;
	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
	self.tableView.scrollsToTop = YES;
	
	[self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]]];
	[self.containerView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]]];
	
	firstLoad = YES;
	
	double delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self relayoutSubviews];
	});
}

- (void)viewDidLayoutSubviews {
	[self relayoutSubviews];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[ATBackend sharedBackend] messageCenterLeftForeground];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[messageDateFormatter release];
	tableView.delegate = nil;
	[tableView release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTableView:nil];
	[self setContainerView:nil];
	[self setInputContainerView:nil];
	[super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	// This metric is added in `ATMessageCenterBaseViewController`. Do not add it twice.
	//[[NSNotificationCenter defaultCenter] postNotificationName:ATMessageCenterDidHideNotification object:nil];
	
	if (self.dismissalDelegate && [self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
		[self.dismissalDelegate messageCenterDidDismiss:self];
	}
}

- (void)scrollToBottom {
	[self scrollToBottomOfTableView];
}

- (void)relayoutSubviews {
	CGFloat viewHeight = self.view.bounds.size.height;
	
	CGRect composerFrame = self.inputContainerView.frame;
	CGRect tableFrame = tableView.frame;
	CGRect containerFrame = self.containerView.frame;
	
	composerFrame.origin.y = viewHeight - self.inputContainerView.frame.size.height;
	
	if (!CGRectEqualToRect(CGRectZero, self.currentKeyboardFrameInView)) {
		CGFloat bottomOffset = viewHeight - composerFrame.size.height;
		CGFloat keyboardOffset = self.currentKeyboardFrameInView.origin.y - composerFrame.size.height;
		composerFrame.origin.y = MIN(bottomOffset, keyboardOffset);
	}
	
	tableFrame.origin.y = 0;
	tableFrame.size.height = composerFrame.origin.y;
	containerFrame.size.height = tableFrame.size.height + composerFrame.size.height;
	
	tableView.frame = tableFrame;
	self.inputContainerView.frame = composerFrame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self relayoutSubviews];
	
	CGRect containerFrame = self.containerView.frame;
	containerFrame.size.height = self.tableView.frame.size.height + self.inputContainerView.frame.size.height;
	self.containerView.frame = containerFrame;
	[self.containerView setNeedsLayout];
	[self relayoutSubviews];
}

#pragma mark Private

- (void)scrollToBottomOfTableView {
	if ([self.tableView numberOfSections] > 0) {
		NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
		if (rowCount > 0) {
			NSUInteger row = rowCount - 1;
			NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
			[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
		}
	}
}

#pragma mark UIScrollViewDelegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return YES;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self tableView:aTableView cellForRowAtIndexPath:indexPath];
	if ([cell conformsToProtocol:@protocol(ATMessageCenterCell)]) {
		return [(NSObject<ATMessageCenterCell> *)cell cellHeightForWidth:aTableView.bounds.size.width];
	}
	return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	if (message != nil && [message.sentByUser boolValue] && [message.pendingState intValue] == ATPendingMessageStateError) {
		[super showRetryMessageActionSheetWithMessage:message];
	} else if (message != nil) {
		UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
		if ([cell isKindOfClass:[ATTextMessageUserCell class]] && [message isKindOfClass:[ATTextMessage class]]) {
			ATTextMessageUserCell *textCell = (ATTextMessageUserCell *)cell;
			ATTextMessage *textMessage = (ATTextMessage *)message;
			if ([textCell isTooLong]) {
				[super showLongMessageControllerWithMessage:textMessage];
			}
		}
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (firstLoad && indexPath.row == 0 && indexPath.section == 0) {
		firstLoad = NO;
		[self scrollToBottomOfTableView];
	}
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = [[[self dataSource].fetchedMessagesController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *UserCellIdentifier = @"ATTextMessageUserCell";
	static NSString *DevCellIdentifier = @"ATTextMessageDevCell";
	
	ATMessageCellType cellType = ATMessageCellTypeUnknown;
	
	UITableViewCell *cell = nil;
	ATAbstractMessage *message = (ATAbstractMessage *)[[self dataSource].fetchedMessagesController objectAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATAutomatedMessage class]]) {
		cellType = ATMessageCellTypeAutomated;
	} else if ([message isKindOfClass:[ATTextMessage class]]) {
		cellType = ATMessageCellTypeText;
	} else if ([message isKindOfClass:[ATFileMessage class]]) {
		cellType = ATMessageCellTypeFile;
	} else {
		NSAssert(NO, @"Unknown cell type");
	}
	
	BOOL showDate = NO;
	NSString *dateString = nil;
	
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
	
	if (cellType == ATMessageCellTypeText) {
		ATTextMessageUserCell *textCell = nil;
		ATTextMessageCellType cellSubType = [message.sentByUser boolValue] ? ATTextMessageCellTypeUser : ATTextMessageCellTypeDeveloper;
		if ([[message pendingState] intValue] == ATPendingMessageStateComposing || [[message pendingState] intValue] == ATPendingMessageStateSending) {
			cellSubType = ATTextMessageCellTypeUser;
		}
		
		if (cellSubType == ATTextMessageCellTypeUser) {
			textCell = (ATTextMessageUserCell *)[tableView dequeueReusableCellWithIdentifier:UserCellIdentifier];
		} else if (cellSubType == ATTextMessageCellTypeDeveloper) {
			textCell = (ATTextMessageUserCell *)[tableView dequeueReusableCellWithIdentifier:DevCellIdentifier];
		}
		
		
		if (!textCell) {
			UINib *nib = [UINib nibWithNibName:@"ATTextMessageUserCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			if (cellSubType == ATTextMessageCellTypeUser) {
				textCell = userCell;
				
				UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 15, 27, 21);
				UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_chat_bubble"];
				UIImage *chatBubbleImage = nil;
				if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
					chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
				} else {
					chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
				}
				textCell.messageBubbleImage.image = chatBubbleImage;
				
				textCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon_default"];
				textCell.usernameLabel.text = ATLocalizedString(@"You", @"User name for text bubbles from users.");
			} else {
				textCell = developerCell;
				
				UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 21, 27, 15);
				UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_dev_chat_bubble"];
				UIImage *chatBubbleImage = nil;
				if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
					chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
				} else {
					chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
				}
				textCell.messageBubbleImage.image = chatBubbleImage;
				
				textCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon_default"];
			}
			[[textCell retain] autorelease];
			[userCell release], userCell = nil;
			[developerCell release], developerCell = nil;
			textCell.selectionStyle = UITableViewCellSelectionStyleNone;
			textCell.userIcon.layer.cornerRadius = 4.0;
			textCell.userIcon.layer.masksToBounds = YES;
			
			textCell.composingBubble.image = [ATBackend imageNamed:@"at_composing_bubble"];
			UIView *backgroundView = [[UIView alloc] init];
			backgroundView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_chat_bg"]];
			textCell.backgroundView = backgroundView;
			[backgroundView release];
		}
		textCell.composing = NO;
		if (cellSubType != ATTextMessageCellTypeUser) {
			textCell.usernameLabel.text = ATLocalizedString(@"Developer", @"User name for text bubbles from developers.");
			if (message.sender.name) {
				textCell.usernameLabel.text = message.sender.name;
			}
		}
		if ([message isKindOfClass:[ATTextMessage class]]) {
			ATMessageSender *sender = [(ATTextMessage *)message sender];
			if (sender.profilePhotoURL) {
				textCell.userIcon.imageURL = [NSURL URLWithString:sender.profilePhotoURL];
			}
			NSString *messageBody = [(ATTextMessage *)message body];
			if ([[message pendingState] intValue] == ATPendingMessageStateSending) {
				NSString *sendingText = ATLocalizedString(@"Sending:", @"Sending prefix on messages that are sending");
				NSString *fullText = [NSString stringWithFormat:@"%@ %@", sendingText, messageBody];
				[textCell.messageText setText:fullText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
					NSRange boldRange = NSMakeRange(0, [sendingText length]);
					
					UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
					CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
					if (font) {
						[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
						CFRelease(font), font = NULL;
					}
					return mutableAttributedString;
				}];
			} else if ([[message pendingState] intValue] == ATPendingMessageStateComposing) {
				textCell.composing = YES;
				textCell.textLabel.text = @"";
			} else if ([[message pendingState] intValue] == ATPendingMessageStateError) {
				NSString *sendingText = NSLocalizedString(@"Error:", @"Error prefix on messages that failed to send");
				NSString *fullText = [NSString stringWithFormat:@"%@ %@", sendingText, messageBody];
				[textCell.messageText setText:fullText afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
					NSRange boldRange = NSMakeRange(0, [sendingText length]);
					
					UIFont *boldFont = [UIFont boldSystemFontOfSize:15];
					UIColor *redColor = [UIColor redColor];
					CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
					if (font) {
						[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
						CFRelease(font), font = NULL;
					}
					[mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)redColor.CGColor range:boldRange];
					return mutableAttributedString;
				}];
			} else {
				textCell.messageText.text = messageBody;
			}
		} else {
			textCell.messageText.text = [message description];
		}
		
		if (showDate) {
			textCell.dateLabel.text = dateString;
			textCell.showDateLabel = YES;
		} else {
			textCell.showDateLabel = NO;
		}
		textCell.tooLong = NO;
		textCell.backgroundColor = [UIColor clearColor];
		
		if (!textCell.composing) {
			CGFloat height = [textCell cellHeightForWidth:aTableView.bounds.size.width];
			if (height > 1024) {
				textCell.tooLong = YES;
			}
		}
		
		cell = textCell;
	} else if (cellType == ATMessageCellTypeAutomated) {
		ATAutomatedMessageCell *currentCell = (ATAutomatedMessageCell *)[tableView dequeueReusableCellWithIdentifier:[ATAutomatedMessageCell reuseIdentifier]];
		
		if (!currentCell) {
			UINib *nib = [UINib nibWithNibName:@"ATAutomatedMessageCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			currentCell = automatedCell;
			[[currentCell retain] autorelease];
			[automatedCell release], automatedCell = nil;
			
			currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		if ([message isKindOfClass:[ATAutomatedMessage class]]) {
			ATAutomatedMessage *automatedMessage = (ATAutomatedMessage *)message;
			NSString *messageTitle = automatedMessage.title;
			NSString *messageBody = automatedMessage.body;
			
			currentCell.titleText.textAlignment = NSTextAlignmentCenter;
			[currentCell.titleText setText:messageTitle afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
				NSRange boldRange = NSMakeRange(0, [mutableAttributedString length]);
				
				UIFont *boldFont = [UIFont fontWithName:@"AmericanTypewriter-Bold" size:15];
				CTFontRef font = CTFontCreateWithName((CFStringRef)[boldFont fontName], [boldFont pointSize], NULL);
				if (font) {
					[mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:boldRange];
					CFRelease(font), font = NULL;
				}
				return mutableAttributedString;
			}];
			currentCell.messageText.text = messageBody;
		}
		currentCell.dateLabel.text = dateString;
		currentCell.showDateLabel = YES;
		currentCell.backgroundColor = [UIColor clearColor];
		
		cell = currentCell;
	} else if (cellType == ATMessageCellTypeFile) {
		ATFileMessageCell *currentCell = (ATFileMessageCell *)[tableView dequeueReusableCellWithIdentifier:[ATFileMessageCell reuseIdentifier]];
		
		if (!currentCell) {
			UINib *nib = [UINib nibWithNibName:@"ATFileMessageCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			currentCell = userFileMessageCell;
			[[currentCell retain] autorelease];
			[userFileMessageCell release], userFileMessageCell = nil;
			
			currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		if ([message isKindOfClass:[ATFileMessage class]]) {
			ATFileMessage *fileMessage = (ATFileMessage *)message;
			[currentCell configureWithFileMessage:fileMessage];
		}
		currentCell.userIcon.image = [ATBackend imageNamed:@"at_mc_user_icon_default"];
		
		
		
		UIEdgeInsets chatInsets = UIEdgeInsetsMake(15, 15, 27, 21);
		UIImage *chatBubbleBase = [ATBackend imageNamed:@"at_chat_bubble"];
		UIImage *chatBubbleImage = nil;
		if ([chatBubbleBase respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
			chatBubbleImage = [chatBubbleBase resizableImageWithCapInsets:chatInsets];
		} else {
			chatBubbleImage = [chatBubbleBase stretchableImageWithLeftCapWidth:chatInsets.left topCapHeight:chatInsets.top];
		}
		currentCell.messageBubbleImage.image = chatBubbleImage;
		
		ATMessageSender *sender = [(ATTextMessage *)message sender];
		if (sender.profilePhotoURL) {
			currentCell.userIcon.imageURL = [NSURL URLWithString:sender.profilePhotoURL];
		}
		if (showDate) {
			currentCell.dateLabel.text = dateString;
			currentCell.showDateLabel = YES;
		} else {
			currentCell.showDateLabel = NO;
		}
		currentCell.backgroundColor = [UIColor clearColor];
		
		cell = currentCell;
	}
	return cell;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		[self.tableView endUpdates];
	}
	@catch (NSException *exception) {
		ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
	[self scrollToBottomOfTableView];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch (type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
			break;
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
}
@end
