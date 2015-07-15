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
#import "ATBackend.h"
#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"
#import "ATNetworkImageView.h"
#import "ATUtilities.h"
#import "ATNetworkImageIconView.h"
#import "ATReachability.h"

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

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextView *messageView;
@property (weak, nonatomic) IBOutlet UIView *sendBar;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendBarTopConstraint;

@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (nonatomic) ATMessageCenterState state;

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
	
	self.inputAccessoryView.layer.borderColor = [[UIColor colorWithRed:215/255.0f green:219/255.0f blue:223/255.0f alpha:1.0f] CGColor];
	self.inputAccessoryView.layer.borderWidth = 0.5;
	
	self.messageInputView.messageView.text = self.draftMessage ?: @"";
	self.messageInputView.sendButton.enabled = self.messageInputView.messageView.text.length > 0;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollInputView:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustInsets:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustInsets:) name:UIKeyboardDidHideNotification object:nil];
	
	[self updateState];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
		[self resizeTextViewForOrientation:toInterfaceOrientation];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self scrollToLastReplyAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self resizeTextViewForOrientation:self.interfaceOrientation];

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
	} else {
		ATMessageCenterReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		cell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		cell.replyLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		cell.senderLabel.text = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		
		return cell;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return [self.dataSource shouldShowDateForMessageGroupAtIndex:section] ? 28.0 : 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL isMessageCell = [self.dataSource cellTypeAtIndexPath:indexPath] == ATMessageCenterMessageTypeMessage;
	
	// iOS 7 requires this and there's no good way to instantiate a cell to sample, so we're hard-coding it for now.
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat marginsAndStuff = isMessageCell ? 30.0 : 74.0;

	// Support iOS 6-style table views
	if (![self.tableView respondsToSelector:@selector(estimatedRowHeight)]) {
		marginsAndStuff += 18.0;
	}
	
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - marginsAndStuff;
	
	CGSize labelSize = [labelText sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(effectiveLabelWidth, MAXFLOAT)];
	
	if (isMessageCell) {
		return labelSize.height + 16.0;
	} else {
		return fmax(labelSize.height + 33.0, 36.0 + 20.0);
	}
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
	headerView.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self adjustBrandingVisibility];
	[self repositionSendBar];
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
	[self scrollToLastReplyAnimated:YES];
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
	
	[self resizeTextViewForOrientation:self.interfaceOrientation];
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
		[[ATBackend sharedBackend] sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {}];
		
		self.messageInputView.messageView.text = @"";
	}
	
	[self resizeTextViewForOrientation:self.interfaceOrientation];
}

- (IBAction)compose:(id)sender {
	self.state = ATMessageCenterStateComposing;
	[self.messageInputView.messageView becomeFirstResponder];
}

#pragma mark - Private

- (void)updateState {
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
				self.state = ATMessageCenterStateComposing;
				break;
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
		
		[self.navigationController setToolbarHidden:(state == ATMessageCenterStateComposing) animated:YES];
		
		_state = state;
		
		switch (state) {
			case ATMessageCenterStateEmpty:
				newFooter = nil;
				self.confirmationView.confirmationHidden = YES;
				break;
				
			case ATMessageCenterStateComposing:
				newFooter = self.messageInputView;
				self.confirmationView.confirmationHidden = YES;
				break;
				
			case ATMessageCenterStateSending:
#warning debug
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = @"Sending...";
				self.confirmationView.statusLabel.text = @"Sending...";
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
		
		void (^animateInBlock)(BOOL finished) = ^(BOOL finished) {
			newFooter.alpha = 0;
			self.tableView.tableFooterView = newFooter;
			
			[UIView animateWithDuration:0.25 animations:^{
				newFooter.alpha = 1;
			}];
		};
		
		if (oldFooter) {
			[UIView animateWithDuration:0.25 animations:^{
				oldFooter.alpha = 0;
			} completion: animateInBlock];
		} else {
			animateInBlock(YES);
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

- (void)adjustInsets:(NSNotification *)notification {
	CGRect messageRect = self.greetingView.frame;
	
	if (self.indexPathOfLastMessage) {
		messageRect = [self.tableView rectForRowAtIndexPath:self.indexPathOfLastMessage];
	}
	
	// Adjust bottom edge inset so that the scroll view will let us scroll last message to top
	UIEdgeInsets edgeInsets = self.tableView.contentInset;
	
	if (self.state == ATMessageCenterStateComposing) {
		edgeInsets.bottom = self.tableView.bounds.size.height - self.messageInputView.bounds.size.height - edgeInsets.top;
	} else {
		edgeInsets.bottom =  self.tableView.bounds.size.height - messageRect.size.height - self.tableView.tableFooterView.bounds.size.height - edgeInsets.top - 16.0;
	}
	self.tableView.contentInset = edgeInsets;
}

- (void)scrollInputView:(NSNotification *)notification {
	[self adjustInsets:notification];
	CGPoint offset = CGPointMake(0.0, CGRectGetMaxY(self.rectOfLastMessage) - self.tableView.contentInset.top);
	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		[self.tableView setContentOffset:offset];
	}];
}

- (void)updateHeaderHeightForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 128.0 : 280.0;

	self.greetingView.bounds = CGRectMake(0, 0, self.tableView.bounds.size.height, headerHeight);
	[self.greetingView updateConstraints];
	self.tableView.tableHeaderView = self.greetingView;
}

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)resizeTextViewForOrientation:(UIInterfaceOrientation)orientation {
	BOOL isLandscapeOnPhone = UIInterfaceOrientationIsLandscape(orientation) && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
	
	CGFloat minHeight = isLandscapeOnPhone ? 32 : 44;
	CGFloat maxHeight = isLandscapeOnPhone ? 100 : 200;
	
	CGFloat preferedHeight = [self.messageInputView.messageView.text sizeWithFont:self.messageInputView.messageView.font constrainedToSize:CGSizeMake(CGRectGetWidth(self.messageView.frame), CGFLOAT_MAX)].height;
	preferedHeight += self.messageInputView.messageView.textContainerInset.top + self.messageInputView.messageView.textContainerInset.bottom;
	
	CGFloat textViewHeight = fmax(minHeight, preferedHeight);
	textViewHeight = fmin(textViewHeight, maxHeight);
		
	[self.inputAccessoryView setNeedsLayout];
}

- (void)scrollToLastReplyAnimated:(BOOL)animated {
	[self adjustInsets:nil];
	
	[self.tableView scrollToRowAtIndexPath:self.indexPathOfLastMessage atScrollPosition:UITableViewScrollPositionTop animated:animated];
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

- (void)repositionSendBar {
	if (self.state != ATMessageCenterStateComposing) {
		return;
	}
	
	CGFloat margin = 0.0;
	
	CGRect footerViewFrame = self.tableView.tableFooterView.frame;
	CGFloat sendBarHeightWithMargins = CGRectGetHeight(self.messageInputView.sendBar.frame) + margin * 2.0;
	
	CGFloat topPosition = CGRectGetMinY(footerViewFrame) - self.tableView.contentOffset.y;
	CGFloat bottomPosition = CGRectGetMaxY(footerViewFrame) - sendBarHeightWithMargins - self.tableView.contentOffset.y;
	
	CGFloat topContentInset = self.tableView.contentInset.top;
	CGFloat offset = 0;
	
	if (topPosition < topContentInset) {
		if (bottomPosition < topContentInset) { // pin it inside the bottom of the view
			offset = CGRectGetHeight(footerViewFrame) - sendBarHeightWithMargins;
		} else {
			offset = topContentInset - topPosition;
		}
	}
	
	self.messageInputView.sendBarTopConstraint.constant = offset;
}

@end
