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
#import "ATMessageCenterWhoView.h"
#import "ATMessageCenterMessageCell.h"
#import "ATMessageCenterReplyCell.h"
#import "ATMessageCenterContextMessageCell.h"
#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"
#import "ATNetworkImageView.h"
#import "ATUtilities.h"
#import "ATNetworkImageIconView.h"
#import "ATReachability.h"
#import "ATAutomatedMessage.h"
#import "ATData.h"
#import "ATProgressNavigationBar.h"
#import "ATAboutViewController.h"

#define HEADER_LABEL_HEIGHT 26.0
#define GREETING_PORTRAIT_HEIGHT 258.0
#define GREETING_LANDSCAPE_HEIGHT 128.0
#define CONFIRMATION_VIEW_HEIGHT 88.0

#define TEXT_VIEW_HORIZONTAL_INSET 12.0
#define TEXT_VIEW_VERTICAL_INSET 10.0
#define DATE_FONT_SIZE 14.0

#define FOOTER_ANIMATION_DURATION 0.10

// The following need to match the storyboard for sizing cells on iOS 7
#define MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN 30.0
#define REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN 74.0
#define MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN 29.0
#define REPLY_LABEL_TOTAL_VERTICAL_MARGIN 46.0
#define REPLY_CELL_MINIMUM_HEIGHT 66.0
#define STATUS_LABEL_HEIGHT 14.0
#define STATUS_LABEL_MARGIN 6.0
#define BODY_FONT_SIZE 17.0

NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
NSString *const ATMessageCenterDidPresentWhoCardKey = @"ATMessageCenterDidPresentWhoCardKey";


typedef NS_ENUM(NSInteger, ATMessageCenterState) {
	ATMessageCenterStateInvalid = 0,
	ATMessageCenterStateEmpty,
	ATMessageCenterStateComposing,
	ATMessageCenterStateWhoCard,
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
@property (strong, nonatomic) IBOutlet ATMessageCenterWhoView *whoView;

@property (strong, nonatomic) IBOutlet UIView *brandingView;
@property (weak, nonatomic) IBOutlet UILabel *poweredByLabel;
@property (weak, nonatomic) IBOutlet UIImageView *poweredByImageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeButtonItem;

@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (nonatomic) ATMessageCenterState state;

@property (nonatomic, strong) ATTextMessage *pendingMessage;
@property (nonatomic, weak) UIView *activeFooterView;

@property (nonatomic, strong) ATAutomatedMessage *contextMessage;

@property (nonatomic, readonly) UIColor *sentColor;
@property (nonatomic, readonly) UIColor *failedColor;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
	
	self.dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];
	
	[ATBackend sharedBackend].messageDelegate = self;
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMdYYYY" options:0 locale:[NSLocale currentLocale]];
	self.dataSource.dateFormatter.dateFormat = self.dateFormatter.dateFormat; // Used to determine if date changed between messages
	
	[self updateHeaderHeightForOrientation:self.interfaceOrientation];
	
	self.navigationItem.title = self.interaction.title;
	
	self.greetingView.titleLabel.text = self.interaction.greetingTitle;
	self.greetingView.messageLabel.text = self.interaction.greetingBody;
	self.greetingView.imageView.imageURL = self.interaction.greetingImageURL;
	
	self.confirmationView.confirmationHidden = YES;
	
	NSString *branding = self.interaction.branding;
	if (branding) {
		
#warning The "Powered By" string needs to come from `self.interaction.branding`.
#warning Need to replace string `Apptentive` with the Apptentive logo image.
		
		self.poweredByLabel.text = ATLocalizedString(@"Powered by", @"Powered by followed by Apptentive logo.");
		self.poweredByImageView.image = [ATBackend imageNamed:@"at_branding_logo"];
		[self.brandingView setNeedsLayout];
		[self.brandingView layoutIfNeeded];
		
		UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.brandingView];
		self.toolbarItems = [@[barButtonItem] arrayByAddingObjectsFromArray:self.toolbarItems];
	}
	
	if (!self.interaction.profileRequested) {
		self.navigationItem.leftBarButtonItem = nil;
	} else {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_account"] landscapeImagePhone:[ATBackend imageNamed:@"at_account"] style:UIBarButtonItemStyleBordered target:self action:@selector(showWho:)];
	}
	
	self.messageInputView.messageView.text = self.draftMessage ?: @"";
	self.messageInputView.messageView.textContainerInset = UIEdgeInsetsMake(TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET);
	[self.messageInputView.clearButton setImage:[ATBackend imageNamed:@"at_ClearButton"] forState:UIControlStateNormal];
	[self.messageInputView.clearButton setImage:[ATBackend imageNamed:@"at_ClearButtonPressed"] forState:UIControlStateHighlighted];
	
	self.messageInputView.placeholderLabel.text = self.interaction.composerPlaceholderText;
	self.messageInputView.placeholderLabel.hidden = self.messageInputView.messageView.text.length > 0;
	
	self.messageInputView.titleLabel.text = self.interaction.composerTitle;
	[self.messageInputView.sendButton setTitle:self.interaction.composerSendButtonTitle forState:UIControlStateNormal];
	self.messageInputView.sendButton.enabled = self.messageInputView.messageView.text.length > 0;
	self.messageInputView.clearButton.enabled = self.messageInputView.messageView.text.length > 0;
	
	self.whoView.titleLabel.text = self.interaction.profileInitialTitle;
	[self.whoView.saveButton setTitle:self.interaction.profileInitialSaveButtonTitle forState:UIControlStateNormal];
	[self.whoView.skipButton setTitle:self.interaction.profileInitialSkipButtonTitle forState:UIControlStateNormal];
	self.whoView.skipButton.hidden = self.interaction.profileRequired;
	self.whoView.nameField.text = [ATConnect sharedConnection].personName;
	self.whoView.emailField.text = [ATConnect sharedConnection].personEmailAddress;
	[self validateWho:self];
	
	self.contextMessage = nil;
	if (self.interaction.contextMessageBody) {
		self.contextMessage = [[ATBackend sharedBackend] automatedMessageWithTitle:nil body:self.interaction.contextMessageBody];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToInputView:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)dealloc {
	self.tableView.delegate = nil;
	self.messageInputView.messageView.delegate = nil;
	self.whoView.nameField.delegate = nil;
	self.whoView.emailField.delegate = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		[self updateHeaderHeightForOrientation:toInterfaceOrientation];
		[self updateFooterViewForOrientation:toInterfaceOrientation];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self updateState];
	[self resizeFooterView:nil];

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
	
	NSString *message = self.pendingMessage ? self.pendingMessage.body : self.messageInputView.messageView.text;
	if (message) {
		[[NSUserDefaults standardUserDefaults] setObject:message forKey:ATMessageCenterDraftMessageKey];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATMessageCenterDraftMessageKey];
	}
	
	[self removeUnsentContextMessages];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.dataSource numberOfMessageGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfMessagesInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.dataSource markAsReadMessageAtIndexPath:indexPath];
	
	UITableViewCell *cell;
	ATMessageCenterMessageType type = [self.dataSource cellTypeAtIndexPath:indexPath];
	
	if (type == ATMessageCenterMessageTypeMessage) {
		ATMessageCenterMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"Message" forIndexPath:indexPath];
	
		messageCell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		switch ([self.dataSource statusOfMessageAtIndexPath:indexPath]) {
			case ATMessageCenterMessageStatusHidden:
				messageCell.statusLabel.hidden = YES;
				messageCell.layer.borderWidth = 0;
				break;
			case ATMessageCenterMessageStatusFailed:
				messageCell.statusLabel.hidden = NO;
				messageCell.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
				cell.layer.borderColor = [self failedColor].CGColor;
				messageCell.statusLabel.textColor = [self failedColor];
				messageCell.statusLabel.text = @"Failed";
				break;
			case ATMessageCenterMessageStatusSending:
				messageCell.statusLabel.hidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = self.sentColor;
				messageCell.statusLabel.text = @"Sending…";
				break;
			case ATMessageCenterMessageStatusSent:
				messageCell.statusLabel.hidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = self.sentColor;
				messageCell.statusLabel.text = @"Sent";
				break;
		}
				
		cell = messageCell;
	} else if (type == ATMessageCenterMessageTypeReply ) {
		ATMessageCenterReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		replyCell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		replyCell.replyLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		replyCell.senderLabel.text = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		
		cell = replyCell;
	} else if (type == ATMessageCenterMessageTypeContextMessage) {
		ATMessageCenterContextMessageCell *contextMessageCell = [tableView dequeueReusableCellWithIdentifier:@"ContextMessage" forIndexPath:indexPath];

		contextMessageCell.contextMessageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];

		cell = contextMessageCell;
	}
	
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height = self.tableView.sectionHeaderHeight;
	
	if ([self.dataSource shouldShowDateForMessageGroupAtIndex:section]) {
		height += HEADER_LABEL_HEIGHT;
	}
	
	return height;
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
	
	if ([self.dataSource statusOfMessageAtIndexPath:indexPath] != ATMessageCenterMessageStatusHidden) {
		verticalMargin += STATUS_LABEL_HEIGHT + STATUS_LABEL_MARGIN;
	}
	
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - horizontalMargin;
	CGSize labelSize = [labelText sizeWithFont:[UIFont systemFontOfSize:BODY_FONT_SIZE] constrainedToSize:CGSizeMake(effectiveLabelWidth, MAXFLOAT)];

	return ceil(fmax(labelSize.height + verticalMargin, minimumCellHeight));
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
	
	if (self.state != ATMessageCenterStateWhoCard && self.state != ATMessageCenterStateComposing) {
		[self updateState];
		
		[self scrollToLastReplyAnimated:YES];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
	
	[self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
		default:
			break;
	}
	
	[self.tableView reloadData];
}

#pragma mark - Text view delegate

- (void)textViewDidChange:(UITextView *)textView {
	self.messageInputView.sendButton.enabled = textView.text.length > 0;
	self.messageInputView.clearButton.enabled = textView.text.length > 0;
	self.messageInputView.placeholderLabel.hidden = textView.text.length > 0;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	self.state = ATMessageCenterStateComposing;

	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[self scrollToInputView:nil];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	if (self.state != ATMessageCenterStateWhoCard)
		[self updateState];
}

// Fix iOS bug where scroll sometimes doesn't follow selection
- (void)textViewDidChangeSelection:(UITextView *)textView {
	[textView scrollRangeToVisible:textView.selectedRange];
}

#pragma mark Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.whoView.nameField) {
		[self.whoView.emailField becomeFirstResponder];
	} else {
		[self saveWho:textField];
		[self.whoView.emailField resignFirstResponder];
	}
	
	return NO;
}

#pragma mark - Message backend delegate

- (void)backend:(ATBackend *)backend messageProgressDidChange:(float)progress {
	ATProgressNavigationBar *navigationBar = (ATProgressNavigationBar *) self.navigationController.navigationBar;
		
	BOOL animated = navigationBar.progressView.progress < progress;
	[navigationBar.progressView setProgress:progress animated:animated];
}

#pragma mark - Actions

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
		NSIndexPath *lastUserMessageIndexPath = self.dataSource.lastUserMessageIndexPath;
		
		[self.messageInputView.messageView resignFirstResponder];
		
		if (self.contextMessage) {
			[[ATBackend sharedBackend] sendAutomatedMessage:self.contextMessage];
			self.contextMessage = nil;
		}
		
		if (self.interaction.profileRequested && ![[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidPresentWhoCardKey]) {
			self.state = ATMessageCenterStateWhoCard;
			self.pendingMessage = [[ATBackend sharedBackend] createTextMessageWithBody:message hiddenOnClient:NO];
		} else {
			[[ATBackend sharedBackend] sendTextMessageWithBody:message];
			[self updateState];
		}
		
		if (lastUserMessageIndexPath) {
			[self.tableView reloadRowsAtIndexPaths:@[lastUserMessageIndexPath] withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	
	self.messageInputView.messageView.text = @"";
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

- (IBAction)showWho:(id)sender {
	self.whoView.skipButton.hidden = NO;
	[self.whoView.saveButton setTitle:self.interaction.profileEditSaveButtonTitle forState:UIControlStateNormal];
	[self.whoView.skipButton setTitle:self.interaction.profileEditSkipButtonTitle forState:UIControlStateNormal];
	
	self.state = ATMessageCenterStateWhoCard;
	[self scrollToInputView:nil];
}

- (IBAction)validateWho:(id)sender {
	BOOL valid = [ATUtilities emailAddressIsValid:self.whoView.emailField.text];
	
	self.whoView.saveButton.enabled = valid;
}

- (IBAction)saveWho:(id)sender {
	if (![ATUtilities emailAddressIsValid:self.whoView.emailField.text]) {
		return;
	}
	
	[ATConnect sharedConnection].personName = self.whoView.nameField.text;
	[ATConnect sharedConnection].personEmailAddress = self.whoView.emailField.text;
	[[ATBackend sharedBackend] updatePersonIfNeeded];
	
	if (self.pendingMessage) {
		NSIndexPath *lastUserMessageIndexPath = self.dataSource.lastUserMessageIndexPath;

		[[ATBackend sharedBackend] sendTextMessage:self.pendingMessage];
		self.pendingMessage = nil;
		
		[self.tableView reloadRowsAtIndexPaths:@[lastUserMessageIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	
	[self updateState];
	[self.view endEditing:YES];
	[self resizeFooterView:nil];

	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ATMessageCenterDidPresentWhoCardKey];
}

- (IBAction)skipWho:(id)sender {
	if (self.pendingMessage) {
		NSIndexPath *lastUserMessageIndexPath = self.dataSource.lastUserMessageIndexPath;

		[[ATBackend sharedBackend] sendTextMessage:self.pendingMessage];
		self.pendingMessage = nil;
		
		[self.tableView reloadRowsAtIndexPaths:@[lastUserMessageIndexPath] withRowAnimation:UITableViewRowAnimationFade];
	}
	
	[self updateState];
	[self.view endEditing:YES];
	[self resizeFooterView:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ATMessageCenterDidPresentWhoCardKey];
}

- (IBAction)showAbout:(id)sender {
	ATAboutViewController *aboutViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"About"];
	
	aboutViewController.interaction = self.interaction;
	[self.navigationController pushViewController:aboutViewController animated:YES];
}

#pragma mark - Private

- (void)updateState {
	if (self.pendingMessage) {
		self.state = ATMessageCenterStateWhoCard;
	} else if (self.dataSource.numberOfMessageGroups == 0) {
		self.state = ATMessageCenterStateEmpty;
	} else if (self.dataSource.lastMessageIsReply) {
		self.state = ATMessageCenterStateReplied;
	} else {
		BOOL networkIsUnreachable = [[ATReachability sharedReachability] currentNetworkStatus] == ATNetworkNotReachable;
		
		switch (self.dataSource.lastUserMessageState) {
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
				//self.state = ATMessageCenterStateComposing;
				break;
			case ATPendingMessageStateNone:
				self.state = ATMessageCenterStateEmpty;
				break;
		}
	}
}

- (void)setState:(ATMessageCenterState)state {
	if (_state != state) {
		UIView *oldFooter = self.activeFooterView;
		UIView *newFooter = nil;
		
		_state = state;
		
		switch (state) {
			case ATMessageCenterStateEmpty:
				newFooter = self.messageInputView;
				break;
				
			case ATMessageCenterStateComposing:
				newFooter = self.messageInputView;
				break;
			
			case ATMessageCenterStateWhoCard:
				[self.whoView.nameField becomeFirstResponder];
				newFooter = self.whoView;
				break;
				
			case ATMessageCenterStateSending:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = YES;
				self.confirmationView.statusLabel.text = nil;
				break;
				
			case ATMessageCenterStateConfirmed:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = YES;
				self.confirmationView.statusLabel.text = self.interaction.statusBody;
				break;
				
			case ATMessageCenterStateNetworkError:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = self.interaction.networkErrorTitle;
				self.confirmationView.statusLabel.text = self.interaction.networkErrorBody;
				break;
				
			case ATMessageCenterStateHTTPError:
				newFooter = self.confirmationView;
				self.confirmationView.confirmationHidden = NO;
				self.confirmationView.confirmationLabel.text = self.interaction.HTTPErrorTitle;
				self.confirmationView.statusLabel.text = self.interaction.networkErrorBody;
				break;
				
			case ATMessageCenterStateReplied:
				newFooter = nil;
				break;
				
			default:
				ATLogError(@"Invalid Message Center State: %d", state);
				break;
		}
		
		if (newFooter != oldFooter) {
			newFooter.alpha = 0;
			newFooter.hidden = NO;

			self.activeFooterView = newFooter;

			[UIView animateWithDuration:0.25 animations:^{
				newFooter.alpha = 1;
				oldFooter.alpha = 0;
			} completion:^(BOOL finished) {
				oldFooter.hidden = YES;
			}];
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
	CGFloat footerSpace = [self.dataSource numberOfMessageGroups] > 0 ? self.tableView.sectionFooterHeight : 0;
	
	CGPoint offset = CGPointMake(0.0, CGRectGetMaxY(self.rectOfLastMessage) - self.tableView.contentInset.top + footerSpace);

	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		[self.tableView setContentOffset:offset];
	}];
}

- (void)resizeFooterView:(NSNotification *)notification {
	CGFloat height = 0;
	
	if (self.state != ATMessageCenterStateEmpty && self.state != ATMessageCenterStateWhoCard && self.state != ATMessageCenterStateComposing) {
		height = CONFIRMATION_VIEW_HEIGHT;
	} else {
		CGRect keyboardRect;
		if (notification) {
			keyboardRect = [self.view.window convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.tableView.superview];
			height = CGRectGetMinY(keyboardRect) - self.tableView.contentInset.top;
			
			if (CGRectGetHeight(CGRectIntersection(keyboardRect, self.view.frame)) == 0) {
				height -= CGRectGetHeight(self.navigationController.toolbar.bounds);
			}
		} else {
			height = CGRectGetHeight(self.tableView.bounds) - self.tableView.contentInset.top - CGRectGetHeight(self.navigationController.toolbar.bounds);
		}
		
		if (self.dataSource.numberOfMessageGroups == 0 && (CGRectGetMinY(keyboardRect) >= CGRectGetMaxY(self.tableView.frame) || !notification)) {
			height -= CGRectGetHeight(self.greetingView.bounds);
		}
	}
	
	CGRect frame = self.tableView.tableFooterView.frame;
	
	frame.size.height = height;
	
	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
		self.tableView.tableFooterView.frame = frame;
		[self.tableView.tableFooterView layoutIfNeeded];
		[self.activeFooterView updateConstraints];
		self.tableView.tableFooterView = self.tableView.tableFooterView;
	}];
}

- (void)updateHeaderHeightForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	CGFloat headerHeight = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? GREETING_LANDSCAPE_HEIGHT : GREETING_PORTRAIT_HEIGHT;

	self.greetingView.bounds = CGRectMake(0, 0, self.tableView.bounds.size.height, headerHeight);
	[self.greetingView updateConstraints];
	self.tableView.tableHeaderView = self.greetingView;
}

- (void)updateFooterViewForOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	[self resizeFooterView:nil];
	[self.activeFooterView updateConstraints];
	self.tableView.tableFooterView = self.tableView.tableFooterView;
}

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)scrollToLastReplyAnimated:(BOOL)animated {
	[self.tableView scrollToRowAtIndexPath:self.indexPathOfLastMessage atScrollPosition:UITableViewScrollPositionTop animated:animated];
}

- (void)removeUnsentContextMessages {
	@synchronized(self) {
		NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(pendingState == %d)", ATPendingMessageStateComposing];
		[ATData removeEntitiesNamed:@"ATAutomatedMessage" withPredicate:fetchPredicate];
	}
}

- (UIColor *)sentColor {
	return [UIColor colorWithRed:0.427 green:0.427 blue:0.447 alpha:1];
}

- (UIColor *)failedColor {
	return [UIColor colorWithRed:0.8 green:0.375 blue:0.412 alpha:1];
}

@end
