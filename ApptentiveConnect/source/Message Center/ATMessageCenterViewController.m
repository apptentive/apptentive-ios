//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterViewController.h"
#import "ATMessageCenterGreetingView.h"
#import "ATMessageCenterConfirmationView.h"
#import "ATMessageCenterInputView.h"
#import "ATMessageCenterMessageCell.h"
#import "ATMessageCenterReplyCell.h"
#import "ATMessageCenterContextMessageCell.h"
#import "ATBackend.h"
#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"
#import "ATNetworkImageView.h"
#import "ATUtilities.h"
#import "ATNetworkImageIconView.h"
#import "ATReachability.h"
#import "ATAutomatedMessage.h"
#import "ATData.h"

#define HEADER_FOOTER_EMPTY_HEIGHT 4.0
#define HEADER_DATE_LABEL_HEIGHT 28.0
#define GREETING_PORTRAIT_HEIGHT 258.0
#define GREETING_LANDSCAPE_HEIGHT 128.0

#define TEXT_VIEW_HORIZONTAL_INSET 12.0
#define TEXT_VIEW_VERTICAL_INSET 10.0
#define DATE_FONT_SIZE 14.0

#define FOOTER_ANIMATION_DURATION 0.25

// The following need to match the storyboard for sizing cells on iOS 7
#define MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN 30.0
#define REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN 74.0
#define MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN 17.0
#define REPLY_LABEL_TOTAL_VERTICAL_MARGIN 34.0
#define REPLY_CELL_MINIMUM_HEIGHT 54.0
#define BODY_FONT_SIZE 14.0

NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";

typedef NS_ENUM(NSInteger, ATMessageCenterState) {
	ATMessageCenterStateInvalid = 0,
	ATMessageCenterStateEmpty,
	ATMessageCenterStateComposing,
	ATMessageCenterStateSending,
	ATMessageCenterStateConfirmed,
	ATMessageCenterStateNetworkError,
	ATMessageCenterStateHTTPError,
	ATMessageCenterStateReplied
};

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ATMessageCenterGreetingView *greetingView;
@property (strong, nonatomic) IBOutlet ATMessageCenterConfirmationView *confirmationView;
@property (strong, nonatomic) IBOutlet ATMessageCenterInputView *messageInputView;

@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel *poweredByLabel;
@property (weak, nonatomic) IBOutlet UIImageView *poweredByImageView;

@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (nonatomic) ATMessageCenterState state;

@property (nonatomic, strong) ATAutomatedMessage *contextMessage;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMdYYYY" options:0 locale:[NSLocale currentLocale]];
	self.dataSource.dateFormatter.dateFormat = self.dateFormatter.dateFormat; // Used to determine if date changed between messages
	
	[self updateHeaderHeightForOrientation:self.interfaceOrientation];
	
	self.navigationItem.title = self.interaction.title;
	
	self.greetingView.titleLabel.text = self.interaction.greetingTitle;
	self.greetingView.messageLabel.text = self.interaction.greetingMessage;
	self.greetingView.imageView.imageURL = self.interaction.greetingImageURL;
	
	if (self.interaction.brandingEnabled) {
		self.tableView.backgroundView = self.backgroundView;
		self.poweredByLabel.text = ATLocalizedString(@"Powered by", @"Powered by followed by Apptentive logo.");
		self.poweredByImageView.image = [ATBackend imageNamed:@"at_branding-logo"];
	}
	
	self.messageInputView.messageView.text = self.draftMessage ?: @"";
	self.messageInputView.messageView.textContainerInset = UIEdgeInsetsMake(TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET);
	[self.messageInputView.clearButton setImage:[ATBackend imageNamed:@"at_ClearButton"] forState:UIControlStateNormal];
	[self.messageInputView.clearButton setImage:[ATBackend imageNamed:@"at_ClearButtonPressed"] forState:UIControlStateHighlighted];
	
	self.messageInputView.placeholderLabel.text = self.interaction.composerPlaceholderText;
	self.messageInputView.placeholderLabel.hidden = self.messageInputView.messageView.text.length > 0;
	
	self.messageInputView.titleLabel.text = self.interaction.composerTitleText;
	self.messageInputView.sendButton.enabled = self.messageInputView.messageView.text.length > 0;
	self.messageInputView.clearButton.enabled = self.messageInputView.messageView.text.length > 0;

	self.tableView.tableFooterView = nil;
	
	self.contextMessage = nil;
	if (self.interaction.contextMessageBody) {
		self.contextMessage = [[ATBackend sharedBackend] automatedMessageWithTitle:nil body:self.interaction.contextMessageBody];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeInputView:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToInputView:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
		[self updateInputViewForOrientation:toInterfaceOrientation];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self updateState];

	if (self.state != ATMessageCenterStateEmpty) {
		[self scrollToLastReplyAnimated:NO];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	NSString *message = self.messageInputView.messageView.text;
	if (message && ![message isEqualToString:@""]) {
		[self.messageInputView.messageView becomeFirstResponder];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSString *message = self.messageInputView.messageView.text;
	if (message) {
		[[NSUserDefaults standardUserDefaults] setObject:message forKey:ATMessageCenterDraftMessageKey];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATMessageCenterDraftMessageKey];
	}
	
	[self removeUnsentContextMessages];
}

- (void)viewDidLayoutSubviews {
	[self adjustBrandingVisibility];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataSource numberOfMessageGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfMessagesInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ATMessageCenterMessageType type = [self.dataSource cellTypeAtIndexPath:indexPath];
	
	[self.dataSource markAsReadMessageAtIndexPath:indexPath];
	
	if (type == ATMessageCenterMessageTypeMessage) {
		ATMessageCenterMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
	
		cell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		
		return cell;
	} else if (type == ATMessageCenterMessageTypeReply ) {
		ATMessageCenterReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		cell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		cell.replyLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		cell.senderLabel.text = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		
		return cell;
	} else if (type == ATMessageCenterMessageTypeContextMessage) {
		ATMessageCenterContextMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContextMessage" forIndexPath:indexPath];
		
		cell.contextMessageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		
		return cell;
	}
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self.dataSource shouldShowDateForMessageGroupAtIndex:section] ? HEADER_DATE_LABEL_HEIGHT : HEADER_FOOTER_EMPTY_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return HEADER_FOOTER_EMPTY_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// iOS 7 requires this and there's no good way to instantiate a cell to sample, so we're hard-coding it for now.
	CGFloat verticalMargin, horizontalMargin, minimumCellHeight;
	
	switch ([self.dataSource cellTypeAtIndexPath:indexPath]) {
		case ATMessageCenterMessageTypeContextMessage:
		case ATMessageCenterMessageTypeMessage:
			horizontalMargin = MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = 0;
			break;
			
		case ATMessageCenterMessageTypeReply:
			horizontalMargin = REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = REPLY_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = REPLY_CELL_MINIMUM_HEIGHT;
			break;
	}
	
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - horizontalMargin;
	CGSize labelSize = [labelText sizeWithFont:[UIFont systemFontOfSize:BODY_FONT_SIZE] constrainedToSize:CGSizeMake(effectiveLabelWidth, MAXFLOAT)];
	
	return fmax(labelSize.height + verticalMargin, minimumCellHeight);
}

#pragma mark Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (![self.dataSource shouldShowDateForMessageGroupAtIndex:section]) {
		return nil;
	}
	
	UITableViewHeaderFooterView *header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Date"];
	
	if (header == nil) {
		header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"Date"];
	}
	
	header.textLabel.text = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageGroupAtIndex:section]];
	
	return header;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
	headerView.textLabel.font = [UIFont boldSystemFontOfSize:DATE_FONT_SIZE];
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == self.tableView) {
		[self adjustBrandingVisibility];
	}
}

#pragma mark Fetch results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	@try {
		[self.tableView endUpdates];
	} @catch (NSException *exception) {
		ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
	}
	
	[self updateState];
	
	if (self.state != ATMessageCenterStateComposing) {
		[self scrollToLastReplyAnimated:YES];
	}
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
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
		default:
			break;
	}
}

#pragma mark Text view delegate

- (void)textViewDidChange:(UITextView *)textView {
	self.messageInputView.sendButton.enabled = textView.text.length > 0;
	self.messageInputView.clearButton.enabled = textView.text.length > 0;
	self.messageInputView.placeholderLabel.hidden = textView.text.length > 0;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	self.state = ATMessageCenterStateComposing;

	return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[self updateState];
}

//- (void)textViewDidBeginEditing:(UITextView *)textView {
//}

// Fix iOS bug where scroll sometimes doesn't follow selection
- (void)textViewDidChangeSelection:(UITextView *)textView
{
	[textView scrollRangeToVisible:textView.selectedRange];
}


#pragma mark Actions

- (IBAction)dismiss:(id)sender {
	[self.dismissalDelegate messageCenterWillDismiss:self];
	[self.dataSource stop];
	
	[self dismissViewControllerAnimated:YES completion:^{
		if ([self.dismissalDelegate respondsToSelector:@selector(messageCenterDidDismiss:)]) {
			[self.dismissalDelegate messageCenterDidDismiss:self];
		}
	}];
}

- (IBAction)sendButtonPressed:(id)sender {
	NSString *message = self.messageInputView.messageView.text;
	
	if (message && ![message isEqualToString:@""]) {
		
		if (self.contextMessage) {
			[[ATBackend sharedBackend] sendAutomatedMessage:self.contextMessage completion:^(NSString *pendingMessageID) {}];
			self.contextMessage = nil;
		}
		
		[[ATBackend sharedBackend] sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {}];
		
		self.messageInputView.messageView.text = @"";
		
		self.state = ATMessageCenterStateSending;
	}
}

- (IBAction)compose:(id)sender {
	self.state = ATMessageCenterStateComposing;
	[self.messageInputView.messageView becomeFirstResponder];
}

- (IBAction)clear:(id)sender {
	self.messageInputView.messageView.text = nil;
	[self.messageInputView.messageView resignFirstResponder];
	
	self.messageInputView.sendButton.enabled = NO;
	self.messageInputView.clearButton.enabled = NO;
	
	[self updateState];
}

#pragma mark - Private

- (void)updateState {
	if (self.state == ATMessageCenterStateComposing) {
		return;
	}
	
	if (self.dataSource.numberOfMessageGroups == 0) {
		self.state = ATMessageCenterStateEmpty;
	} else if (self.dataSource.lastMessageIsReply) {
		self.state = ATMessageCenterStateReplied;
	} else {
		BOOL networkIsUnreachable = [[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable;
		
		switch (self.dataSource.lastSentMessageState) {
			case ATPendingMessageStateConfirmed:
				self.state = ATMessageCenterStateConfirmed;
				break;
			case ATPendingMessageStateError:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateHTTPError;
				break;
			case ATPendingMessageStateSending:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateSending;
				break;
			case ATPendingMessageStateComposing:
			case ATPendingMessageStateNone:
				self.state = ATMessageCenterStateEmpty;
				break;
		}
	}
}

- (void)setState:(ATMessageCenterState)state {
	if (_state != state) {
		UIView *oldFooter = self.tableView.tableFooterView;
		UIView *newFooter = nil;
		
		[self.navigationController setToolbarHidden:(state == ATMessageCenterStateComposing || state == ATMessageCenterStateEmpty) animated:YES];
		
		_state = state;
		
		switch (state) {
			case ATMessageCenterStateEmpty:
				newFooter = self.messageInputView;
				CGFloat navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
				CGFloat statusBarHeight = fmin(CGRectGetHeight([UIApplication sharedApplication].statusBarFrame), CGRectGetWidth([UIApplication sharedApplication].statusBarFrame));
				
				self.messageInputView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(self.tableView.bounds) - CGRectGetHeight(self.greetingView.bounds) - navigationBarHeight - statusBarHeight);
				self.confirmationView.confirmationHidden = YES;
				break;
				
			case ATMessageCenterStateComposing:
				newFooter = self.messageInputView;
				self.confirmationView.confirmationHidden = YES;
				break;
				
			case ATMessageCenterStateSending:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = YES;
				break;
				
			case ATMessageCenterStateConfirmed:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = self.interaction.confirmationText;
				self.confirmationView.statusLabel.text = self.interaction.statusText;
				break;
				
			case ATMessageCenterStateNetworkError:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = self.interaction.networkErrorTitle;
				self.confirmationView.statusLabel.text = self.interaction.networkErrorMessage;
				break;
				
			case ATMessageCenterStateHTTPError:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = self.interaction.HTTPErrorTitle;
				self.confirmationView.statusLabel.text = self.interaction.HTTPErrorMessage;
				break;
				
			case ATMessageCenterStateReplied:
				newFooter = nil;
				break;
				
			default:
				ATLogError(@"Invalid Message Center State: %d", state);
				break;
		}
		
		if (newFooter != oldFooter) {
			void (^animateInBlock)(BOOL finished) = ^(BOOL finished) {
				newFooter.alpha = 0;
				self.tableView.tableFooterView = newFooter;
				
				[UIView animateWithDuration:FOOTER_ANIMATION_DURATION animations:^{
					newFooter.alpha = 1;
				}];
			};
			
			if (oldFooter) {
				[UIView animateWithDuration:FOOTER_ANIMATION_DURATION animations:^{
					oldFooter.alpha = 0;
				} completion: animateInBlock];
			} else {
				animateInBlock(YES);
			}
		} else {
			// Inform table view that footer may have resized
			self.tableView.tableFooterView = newFooter;
		}
	}
}

- (NSIndexPath *)indexPathOfLastMessage {
	NSInteger lastSectionIndex = self.tableView.numberOfSections - 1;
	
	if (lastSectionIndex == -1) {
		return nil;
	}
	
	NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex] - 1;
	
	if (lastRowIndex == -1) {
		return nil;
	}
	
	return [NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex];
}

- (CGRect)rectOfLastMessage {
	NSIndexPath *indexPath = self.indexPathOfLastMessage;
	
	if (indexPath) {
		return [self.tableView rectForRowAtIndexPath:indexPath];
	} else {
		return self.greetingView.frame;
	}
}

- (void)scrollToInputView:(NSNotification *)notification {
	CGPoint offset = CGPointMake(0.0, CGRectGetMaxY(self.rectOfLastMessage) - self.tableView.contentInset.top);
	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		[self.tableView setContentOffset:offset];
	}];
}

- (void)resizeInputView:(NSNotification *)notification {
	CGFloat height = 0;

	if (self.state == ATMessageCenterStateComposing) {
		CGRect rect = [self.view.window convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.tableView];
		
		height = CGRectGetHeight(self.tableView.bounds) - CGRectGetHeight(rect) - [self.topLayoutGuide length];
	} else if (self.state == ATMessageCenterStateEmpty) {
		height = CGRectGetHeight(self.tableView.bounds) - CGRectGetHeight(self.greetingView.bounds) - [self.topLayoutGuide length];
	} else {
		return;
	}
	
	CGRect frame = self.messageInputView.frame;
	
	frame.size.height = height;
	
	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		self.messageInputView.frame = frame;
		
		if (self.tableView.tableFooterView == self.messageInputView) {
			self.tableView.tableFooterView = self.messageInputView;
		}
		
		[self.messageInputView updateConstraints];
	}];
}

- (void)updateHeaderHeightForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? GREETING_LANDSCAPE_HEIGHT	: GREETING_PORTRAIT_HEIGHT;

	self.greetingView.bounds = CGRectMake(0, 0, self.tableView.bounds.size.height, headerHeight);
	[self.greetingView updateConstraints];
	self.tableView.tableHeaderView = self.greetingView;
}

- (void)updateInputViewForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	if (self.tableView.tableFooterView == self.messageInputView) {
		[self resizeInputView:nil];
		[self.messageInputView updateConstraints];
		self.tableView.tableFooterView = self.messageInputView;
	}
}

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)scrollToLastReplyAnimated:(BOOL)animated {
	[self.tableView scrollToRowAtIndexPath:self.indexPathOfLastMessage atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)adjustBrandingVisibility {
	// Hide branding when content gets within transtionDistance of it
	CGFloat transitionDistance = 44;
	
	CGFloat confirmationViewHeight = CGRectGetHeight(self.confirmationView.bounds);
	CGFloat poweredByTop = CGRectGetMinY(self.poweredByLabel.frame);
	
	CGRect lastMessageFrame = self.greetingView.frame;
	if (self.indexPathOfLastMessage) {
		lastMessageFrame = [self.tableView rectForRowAtIndexPath:self.indexPathOfLastMessage];
	}
	
	CGFloat lastMessageBottom = CGRectGetMaxY([self.backgroundView convertRect:lastMessageFrame fromView:self.tableView]);
	
	CGFloat distance = poweredByTop - lastMessageBottom - confirmationViewHeight;
	
	if (distance > transitionDistance) {
		self.tableView.backgroundView.alpha = 1.0;
	} else if (distance < 0) {
		self.tableView.backgroundView.alpha = 0.0;
	} else {
		self.tableView.backgroundView.alpha = distance / transitionDistance;
	}
}

- (void)removeUnsentContextMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATAutomatedMessage" withPredicate:fetchPredicate];
	}
}

@end
