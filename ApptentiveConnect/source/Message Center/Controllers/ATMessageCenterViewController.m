//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ATMessageCenterViewController.h"
#import "ATMessageCenterGreetingView.h"
#import "ATMessageCenterStatusView.h"
#import "ATMessageCenterInputView.h"
#import "ATMessageCenterProfileView.h"
#import "ATMessageCenterMessageCell.h"
#import "ATMessageCenterReplyCell.h"
#import "ATMessageCenterContextMessageCell.h"
#import "ATCompoundMessageCell.h"
#import "ATMessageCenterInteraction.h"
#import "ATConnect_Private.h"
#import "ATNetworkImageView.h"
#import "ATUtilities.h"
#import "ATNetworkImageIconView.h"
#import "ATReachability.h"
#import "ATProgressNavigationBar.h"
#import "ATAboutViewController.h"
#import "ATAttachButton.h"
#import "ATAttachmentController.h"
#import "ATIndexedCollectionView.h"
#import "ATAttachmentCell.h"
#import <MobileCoreServices/UTCoreTypes.h>

#define HEADER_LABEL_HEIGHT 64.0
#define TEXT_VIEW_HORIZONTAL_INSET 12.0
#define TEXT_VIEW_VERTICAL_INSET 10.0
#define DATE_FONT [UIFont boldSystemFontOfSize:14.0]
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)

#define FOOTER_ANIMATION_DURATION 0.10

// The following need to match the storyboard for sizing cells on iOS 7
#define MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN 30.0
#define REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN 74.0
#define MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN 29.0
#define REPLY_LABEL_TOTAL_VERTICAL_MARGIN 46.0
#define REPLY_CELL_MINIMUM_HEIGHT 66.0
#define STATUS_LABEL_HEIGHT 14.0
#define STATUS_LABEL_MARGIN 6.0
#define BODY_FONT [UIFont systemFontOfSize:17.0]

NSString *const ATInteractionMessageCenterEventLabelLaunch = @"launch";
NSString *const ATInteractionMessageCenterEventLabelClose = @"close";
NSString *const ATInteractionMessageCenterEventLabelAttach = @"attach";

NSString *const ATInteractionMessageCenterEventLabelComposeOpen = @"compose_open";
NSString *const ATInteractionMessageCenterEventLabelComposeClose = @"compose_close";
NSString *const ATInteractionMessageCenterEventLabelKeyboardOpen = @"keyboard_open";
NSString *const ATInteractionMessageCenterEventLabelKeyboardClose = @"keyboard_close";

NSString *const ATInteractionMessageCenterEventLabelGreetingMessage = @"greeting_message";
NSString *const ATInteractionMessageCenterEventLabelStatus = @"status";
NSString *const ATInteractionMessageCenterEventLabelHTTPError = @"message_http_error";
NSString *const ATInteractionMessageCenterEventLabelNetworkError = @"message_network_error";

NSString *const ATInteractionMessageCenterEventLabelProfileOpen = @"profile_open";
NSString *const ATInteractionMessageCenterEventLabelProfileClose = @"profile_close";
NSString *const ATInteractionMessageCenterEventLabelProfileName = @"profile_name";
NSString *const ATInteractionMessageCenterEventLabelProfileEmail = @"profile_email";
NSString *const ATInteractionMessageCenterEventLabelProfileSubmit = @"profile_submit";

NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
NSString *const ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";

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
@property (strong, nonatomic) IBOutlet ATMessageCenterStatusView *statusView;
@property (strong, nonatomic) IBOutlet ATMessageCenterInputView *messageInputView;
@property (strong, nonatomic) IBOutlet ATMessageCenterProfileView *profileView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *neuMessageButtonItem; // newMessageButtonItem

@property (nonatomic, strong) IBOutlet ATAttachmentController *attachmentController;

@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (nonatomic) ATMessageCenterState state;

@property (nonatomic, weak) UIView *activeFooterView;

@property (nonatomic, strong) ATMessage *contextMessage;

@property (nonatomic, readonly) UIColor *sentColor;
@property (nonatomic, readonly) UIColor *failedColor;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
	// TODO: Figure out a way to avoid tightly coupling this
	[ATBackend sharedBackend].presentedMessageCenterViewController = self;
	
    [super viewDidLoad];
	
	[self.interaction engage:ATInteractionMessageCenterEventLabelLaunch fromViewController:self];
	
	[self.navigationController.toolbar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(compose:)]];
	
	self.navigationItem.rightBarButtonItem.title = ATLocalizedString(@"Close", @"Button that closes Message Center.");
	self.navigationItem.rightBarButtonItem.accessibilityHint = ATLocalizedString(@"Closes Message Center.", @"Accessibility hint for 'close' button");
	
	self.dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];
	
	[ATBackend sharedBackend].messageDelegate = self;
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMdyyyy" options:0 locale:[NSLocale currentLocale]];
	self.dataSource.dateFormatter.dateFormat = self.dateFormatter.dateFormat; // Used to determine if date changed between messages
	
	self.greetingView.orientation = self.interfaceOrientation;
	self.profileView.orientation = self.interfaceOrientation;
	self.messageInputView.orientation = self.interfaceOrientation;

	self.navigationItem.title = self.interaction.title;
	
	self.greetingView.titleLabel.text = self.interaction.greetingTitle;
	self.greetingView.messageLabel.text = self.interaction.greetingBody;
	self.greetingView.imageView.imageURL = self.interaction.greetingImageURL;
	self.greetingView.aboutButton.hidden = !self.interaction.branding;
	self.greetingView.isOnScreen = NO;
	
	[self.greetingView.aboutButton setImage:[[ATBackend imageNamed:@"at_info"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	self.greetingView.aboutButton.accessibilityLabel = ATLocalizedString(@"About Apptentive", @"Accessibility label for 'show about' button");
	self.greetingView.aboutButton.accessibilityHint = ATLocalizedString(@"Displays information about this feature.", @"Accessibilty hint for 'show about' button");
	
	self.statusView.mode = ATMessageCenterStatusModeEmpty;
	
	self.messageInputView.messageView.text = self.draftMessage ?: @"";
	self.messageInputView.messageView.textContainerInset = UIEdgeInsetsMake(TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET);
	[self.messageInputView.clearButton setImage:[[ATBackend imageNamed:@"at_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	
	self.messageInputView.placeholderLabel.text = self.interaction.composerPlaceholderText;
	self.messageInputView.placeholderLabel.hidden = self.messageInputView.messageView.text.length > 0;
	
	self.messageInputView.titleLabel.text = self.interaction.composerTitle;
	[self.messageInputView.sendButton setTitle:self.interaction.composerSendButtonTitle forState:UIControlStateNormal];
	self.messageInputView.sendButton.enabled = [self sendButtonShouldBeEnabled];
	
	self.messageInputView.sendButton.accessibilityHint = ATLocalizedString(@"Sends the message.", @"Accessibility hint for 'send' button");
	
	self.messageInputView.clearButton.accessibilityLabel = ATLocalizedString(@"Discard", @"Accessibility label for 'discard' button");
	self.messageInputView.clearButton.accessibilityHint = ATLocalizedString(@"Discards the message.", @"Accessibility hint for 'discard' button");

	[self.messageInputView.attachButton setImage:[ATBackend imageNamed:@"at_attach"] forState:UIControlStateNormal];
	self.messageInputView.attachButton.accessibilityLabel = ATLocalizedString(@"Attach", @"Accessibility label for 'attach' button");
	self.messageInputView.attachButton.accessibilityHint = ATLocalizedString(@"Attaches a photo or screenshot", @"Accessibility hint for 'attach'");

	if (self.interaction.profileRequested) {
		UIBarButtonItem *profileButtonItem = [[UIBarButtonItem alloc] initWithImage:[ATBackend imageNamed:@"at_account"] landscapeImagePhone:[ATBackend imageNamed:@"at_account"] style:UIBarButtonItemStyleBordered target:self action:@selector(showWho:)];
		profileButtonItem.accessibilityLabel = ATLocalizedString(@"Profile", @"Accessibility label for 'edit profile' button");
		profileButtonItem.accessibilityHint = ATLocalizedString(@"Displays name and email editor.", @"Accessibility hint for 'edit profile' button");
		self.navigationItem.leftBarButtonItem = profileButtonItem;
		
		self.profileView.titleLabel.text = self.interaction.profileInitialTitle;
		self.profileView.requiredLabel.text = self.interaction.profileInitialEmailExplanation;
		[self.profileView.saveButton setTitle:self.interaction.profileInitialSaveButtonTitle forState:UIControlStateNormal];
		[self.profileView.skipButton setTitle:self.interaction.profileInitialSkipButtonTitle forState:UIControlStateNormal];
		self.profileView.skipButton.hidden = self.interaction.profileRequired;
		[self validateWho:self];

		if (self.interaction.profileRequired && [self shouldShowProfileViewBeforeComposing:YES]) {
			self.profileView.skipButton.hidden = YES;
			self.profileView.mode = ATMessageCenterProfileModeCompact;
			
			self.composeButtonItem.enabled = NO;
			self.neuMessageButtonItem.enabled = NO;
		} else {
			self.profileView.mode = ATMessageCenterProfileModeFull;
		}
	} else {
		self.navigationItem.leftBarButtonItem = nil;
	}
	
	self.contextMessage = nil;
	if (self.interaction.contextMessageBody) {
		self.contextMessage = [[ATBackend sharedBackend] automatedMessageWithTitle:nil body:self.interaction.contextMessageBody];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToFooterView:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];

	// Fix iOS 7 bug where contentSize gets set to zero
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fixContentSize:) name:UIKeyboardDidShowNotification object:nil];

	[self.attachmentController viewDidLoad];
}

- (void)dealloc {
	[self.dataSource removeUnsentContextMessages];

	self.tableView.delegate = nil;
	self.messageInputView.messageView.delegate = nil;
	self.profileView.nameField.delegate = nil;
	self.profileView.emailField.delegate = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[UIView animateWithDuration:duration animations:^{
		self.greetingView.orientation = toInterfaceOrientation;
		self.profileView.orientation = toInterfaceOrientation;
		self.messageInputView.orientation = toInterfaceOrientation;
		
		self.tableView.tableHeaderView = self.greetingView;
		[self resizeFooterView:nil];
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	NSString *message = self.messageInputView.messageView.text;
	
	if (self.attachmentController.active) {
		self.state = ATMessageCenterStateComposing;
		[self.attachmentController becomeFirstResponder];
	} else if (message && ![message isEqualToString:@""]) {
		self.state = ATMessageCenterStateComposing;
		[self.messageInputView.messageView becomeFirstResponder];
	} else {
		[self updateState];
	}
	[self resizeFooterView:nil];
	[self engageGreetingViewEventIfNecessary];
	[self scrollToLastMessageAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self saveDraft];

	[[ATBackend sharedBackend] messageCenterWillDismiss:self];
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
	
	UITableViewCell<ATMessageCenterCell> *cell;
	ATMessageCenterMessageType type = [self.dataSource cellTypeAtIndexPath:indexPath];
	
	if (type == ATMessageCenterMessageTypeMessage || type == ATMessageCenterMessageTypeCompoundMessage) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundMessage ? @"CompoundMessage" : @"Message";
		ATMessageCenterMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	
		switch ([self.dataSource statusOfMessageAtIndexPath:indexPath]) {
			case ATMessageCenterMessageStatusHidden:
				messageCell.statusLabelHidden = YES;
				messageCell.layer.borderWidth = 0;
				break;
			case ATMessageCenterMessageStatusFailed:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
				messageCell.layer.borderColor = [self failedColor].CGColor;
				messageCell.statusLabel.textColor = [self failedColor];
				messageCell.statusLabel.text = ATLocalizedString(@"Failed", @"Message failed to send.");
				break;
			case ATMessageCenterMessageStatusSending:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = self.sentColor;
				messageCell.statusLabel.text = ATLocalizedString(@"Sending…", @"Message is sending.");
				break;
			case ATMessageCenterMessageStatusSent:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = self.sentColor;
				messageCell.statusLabel.text = ATLocalizedString(@"Sent", @"Message sent successfully");
				break;
		}

		cell = messageCell;
	} else if (type == ATMessageCenterMessageTypeReply || type == ATMessageCenterMessageTypeCompoundReply) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundReply ? @"CompoundReply" : @"Reply";
		ATMessageCenterReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

		replyCell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		replyCell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		replyCell.senderLabel.text = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		
		cell = replyCell;
	} else if (type == ATMessageCenterMessageTypeContextMessage) {
		// TODO: handle title
		ATMessageCenterContextMessageCell *contextMessageCell = [tableView dequeueReusableCellWithIdentifier:@"ContextMessage" forIndexPath:indexPath];

		cell = contextMessageCell;
	}

	if (type == ATMessageCenterMessageTypeCompoundMessage || type == ATMessageCenterMessageTypeCompoundReply) {
		UITableViewCell<ATMessageCenterCompoundCell> *compoundCell = (ATCompoundMessageCell *)cell;

		compoundCell.collectionView.index = indexPath.section;
		compoundCell.collectionView.dataSource = self;
		compoundCell.collectionView.delegate = self;

		UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)compoundCell.collectionView.collectionViewLayout;
		layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width, ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width);
		layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
		layout.itemSize = [ATAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN];

		compoundCell.messageLabelHidden = compoundCell.messageLabel.text == nil;
	}

	cell.messageLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];

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
	BOOL statusLabelVisible = [self.dataSource statusOfMessageAtIndexPath:indexPath] != ATMessageCenterMessageStatusHidden;
	CGFloat verticalFudgeFactor = 0.0;
	
	switch ([self.dataSource cellTypeAtIndexPath:indexPath]) {
		case ATMessageCenterMessageTypeContextMessage:
		case ATMessageCenterMessageTypeMessage:
			horizontalMargin = MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = 0;
			break;

		case ATMessageCenterMessageTypeCompoundMessage:
			horizontalMargin = MESSAGE_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN + [ATAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN] - ATTACHMENT_MARGIN.height;
			verticalFudgeFactor = 19.0;
			minimumCellHeight = 0;
			break;

		case ATMessageCenterMessageTypeReply:
			horizontalMargin = REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = REPLY_LABEL_TOTAL_VERTICAL_MARGIN;
			minimumCellHeight = REPLY_CELL_MINIMUM_HEIGHT;
			break;

		case ATMessageCenterMessageTypeCompoundReply:
			horizontalMargin = REPLY_LABEL_TOTAL_HORIZONTAL_MARGIN;
			verticalMargin = REPLY_LABEL_TOTAL_VERTICAL_MARGIN + [ATAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN] - ATTACHMENT_MARGIN.height;
			minimumCellHeight = REPLY_CELL_MINIMUM_HEIGHT + [ATAttachmentCell heightForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN] - ATTACHMENT_MARGIN.height;
			break;
	}
	
	if (statusLabelVisible) {
		verticalMargin += STATUS_LABEL_HEIGHT + STATUS_LABEL_MARGIN + verticalFudgeFactor;
	}
	
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - horizontalMargin;
	CGRect labelRect = CGRectZero;
	if (labelText) {
		NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:labelText attributes:@{NSFontAttributeName: BODY_FONT}];
		labelRect = [attributedText boundingRectWithSize:CGSizeMake(effectiveLabelWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
	} else {
		verticalMargin -= MESSAGE_LABEL_TOTAL_VERTICAL_MARGIN;
		if (statusLabelVisible) {
			verticalMargin += 9.0;
		}
	}
	
	double height = ceil(fmax(labelRect.size.height + verticalMargin, minimumCellHeight));
	
	// "Due to an underlying implementation detail, you should not return values greater than 2009."
	return fmin(height, 2009.0);
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
	headerView.textLabel.font = DATE_FONT;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	if (indexPath) {
		[[UIPasteboard generalPasteboard] setValue:[self.dataSource textOfMessageAtIndexPath:indexPath] forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];
	}
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self engageGreetingViewEventIfNecessary];
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
		
		[self resizeFooterView:nil];
		[self scrollToLastMessageAnimated:YES];
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	switch(type) {
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;

		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
			
		case NSFetchedResultsChangeMove:
			if (![indexPath isEqual:newIndexPath]) {
				[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
				[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
			break;
			
		default:
			break;
	}
	
	[self.tableView reloadData];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
		case NSFetchedResultsChangeUpdate:
			[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;
		default:
			break;
	}
	
	[self.tableView reloadData];
}

#pragma mark Message center data source delegate

- (void)messageCenterDataSource:(ATMessageCenterDataSource *)dataSource didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath {
	ATCompoundMessageCell *cell = (ATCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ATIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ATAttachmentCell *attachmentCell = (ATAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];
	attachmentCell.progressView.hidden = YES;

	[collectionView reloadItemsAtIndexPaths:@[ collectionViewIndexPath ]];
}

- (void)messageCenterDataSource:(ATMessageCenterDataSource *)dataSource attachmentDownloadAtIndexPath:(NSIndexPath *)indexPath didProgress:(float)progress {
	ATCompoundMessageCell *cell = (ATCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ATIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ATAttachmentCell *attachmentCell = (ATAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = NO;
	[attachmentCell.progressView setProgress:progress animated:YES];
}

- (void)messageCenterDataSource:(ATMessageCenterDataSource *)dataSource didFailToLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error {
	ATCompoundMessageCell *cell = (ATCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ATIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ATAttachmentCell *attachmentCell = (ATAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = YES;
	attachmentCell.progressView.progress = 0;

	[[[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Unable to Download Attachment", @"Attachment download failed alert title") message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ATIndexedCollectionView *)collectionView).index];

	if ([self.dataSource shouldUsePlaceholderForAttachmentAtIndexPath:attachmentIndexPath]) {
		[self.dataSource downloadAttachmentAtIndexPath:attachmentIndexPath];
	} else {
		// TODO: display preview of attachment
	}
}

#pragma mark Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.dataSource numberOfAttachmentsForMessageAtIndex:((ATIndexedCollectionView *)collectionView).index];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ATAttachmentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Attachment" forIndexPath:indexPath];
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ATIndexedCollectionView *)collectionView).index];

	cell.usePlaceholder = [self.dataSource shouldUsePlaceholderForAttachmentAtIndexPath:attachmentIndexPath];
	cell.imageView.image = [self.dataSource imageForAttachmentAtIndexPath:attachmentIndexPath size:[ATAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN]];
	cell.extensionLabel.text = [self.dataSource extensionForAttachmentAtIndexPath:attachmentIndexPath];

	return cell;
}

#pragma mark - Text view delegate

- (void)textViewDidChange:(UITextView *)textView {
	self.messageInputView.sendButton.enabled = [self sendButtonShouldBeEnabled];
	self.messageInputView.placeholderLabel.hidden = textView.text.length > 0;
	
	// Fix bug where text view doesn't scroll far enough down
	// Adapted from http://stackoverflow.com/a/19277383/27951
	CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
	CGFloat overflow = line.origin.y + line.size.height - ( textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top );
	if ( overflow > 0 ) {
		// Scroll caret to visible area
		CGPoint offset = textView.contentOffset;
		offset.y += overflow + textView.textContainerInset.bottom;
		
		// Cannot animate with setContentOffset:animated: or caret will not appear
		[UIView animateWithDuration:.2 animations:^{
			[textView setContentOffset:offset];
		}];
	}
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	self.state = ATMessageCenterStateComposing;

	return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	self.attachmentController.active = NO;

	[self scrollToFooterView:nil];
}

#pragma mark Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.profileView.nameField) {
		[self.profileView.emailField becomeFirstResponder];
	} else {
		[self saveWho:textField];
		[self.profileView.emailField resignFirstResponder];
	}
	
	return NO;
}

#pragma mark - Message backend delegate

- (void)backend:(ATBackend *)backend messageProgressDidChange:(float)progress {
	ATProgressNavigationBar *navigationBar = (ATProgressNavigationBar *) self.navigationController.navigationBar;
		
	BOOL animated = navigationBar.progressView.progress < progress;
	[navigationBar.progressView setProgress:progress animated:animated];
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.destructiveButtonIndex) {
		[self discardDraft];
	}
}

#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
	[self.attachmentController resignFirstResponder];

	[self.interaction engage:ATInteractionMessageCenterEventLabelClose fromViewController:self];
	
	[self.dataSource stop];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)sendButtonShouldBeEnabled {
	NSString *inputText = self.messageInputView.messageView.text;

	if (!inputText || inputText.length == 0) {
		return NO;
	}
	
	if ([inputText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
		return NO;
	}
	
	return YES;
}

- (IBAction)sendButtonPressed:(id)sender {
	NSString *message = self.messageInputView.messageView.text;
	
	if (message && ![message isEqualToString:@""]) {
		NSIndexPath *lastUserMessageIndexPath = self.dataSource.lastUserMessageIndexPath;
		
		if (self.contextMessage) {
			[[ATBackend sharedBackend] sendAutomatedMessage:self.contextMessage];
			self.contextMessage = nil;
		}

		NSArray *attachments = self.attachmentController.attachments;
		if (attachments.count) {
			[[ATBackend sharedBackend] sendCompoundMessageWithText:message attachments:attachments hiddenOnClient:NO];
			[self.attachmentController clear];
		} else {
			[[ATBackend sharedBackend] sendTextMessageWithBody:message];
		}

		[self.attachmentController resignFirstResponder];

		if ([self shouldShowProfileViewBeforeComposing:NO]) {
			[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{@"required": @(self.interaction.profileRequired), @"trigger": @"automatic"}];
			
			self.state = ATMessageCenterStateWhoCard;
		} else {
			[self.messageInputView.messageView resignFirstResponder];
			[self updateState];
		}
	
		if (lastUserMessageIndexPath) {
			@try {
				//[self.tableView reloadRowsAtIndexPaths:@[lastUserMessageIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			} @catch (NSException *exception) {
				ATLogError(@"caught exception: %@: %@", [exception name], [exception description]);
			}
		}
	}
	
	self.messageInputView.messageView.text = @"";
}

- (IBAction)compose:(id)sender {
	self.state = ATMessageCenterStateComposing;
	[self.messageInputView.messageView becomeFirstResponder];
}

- (IBAction)clear:(UIButton *)sender {
	if (self.messageInputView.messageView.text.length == 0 && self.attachmentController.attachments.count == 0) {
		[self discardDraft];
		return;
	}
	
	if (NSClassFromString(@"UIAlertController")) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.interaction.composerCloseConfirmBody message:nil preferredStyle:UIAlertControllerStyleActionSheet];
		
		[alertController addAction:[UIAlertAction actionWithTitle:self.interaction.composerCloseCancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
		[alertController addAction:[UIAlertAction actionWithTitle:self.interaction.composerCloseDiscardButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
			[self discardDraft];
		}]];
		
		[self presentViewController:alertController animated:YES completion:nil];
	} else {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:self.interaction.composerCloseConfirmBody delegate:self cancelButtonTitle:self.interaction.composerCloseCancelButtonTitle destructiveButtonTitle:self.interaction.composerCloseDiscardButtonTitle otherButtonTitles:nil];
		
		if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			[actionSheet showFromRect:sender.frame inView:sender.superview animated:YES];
		} else {
			[actionSheet showFromToolbar:self.navigationController.toolbar];
		}
	}
}

- (IBAction)showWho:(id)sender {
	self.profileView.mode = ATMessageCenterProfileModeFull;
	
	self.profileView.skipButton.hidden = NO;
	self.profileView.titleLabel.text = self.interaction.profileEditTitle;
	
	self.profileView.nameField.placeholder = self.interaction.profileEditNamePlaceholder;
	self.profileView.emailField.placeholder = self.interaction.profileEditEmailPlaceholder;
	
	[self.profileView.saveButton setTitle:self.interaction.profileEditSaveButtonTitle forState:UIControlStateNormal];
	[self.profileView.skipButton setTitle:self.interaction.profileEditSkipButtonTitle forState:UIControlStateNormal];
	
	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{@"required": @(self.interaction.profileRequired), @"trigger": @"button"}];
	
	self.state = ATMessageCenterStateWhoCard;
	
	[self resizeFooterView:nil];
	[self scrollToFooterView:nil];
}

- (IBAction)validateWho:(id)sender {
	self.profileView.saveButton.enabled = [self isWhoValid];
}

- (IBAction)saveWho:(id)sender {
	if (![self isWhoValid]) {
		return;
	}
	
	NSString *buttonLabel = nil;
	if ([sender isKindOfClass:[UIButton class]]) {
		buttonLabel = ((UIButton *)sender).titleLabel.text;
	} else if ([sender isKindOfClass:[UITextField class]]) {
		buttonLabel = @"return_key";
	}
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:@(self.interaction.profileRequired) forKey:@"required"];
	if (buttonLabel) {
		[userInfo setObject:buttonLabel forKey:@"button_label"];
	}
	
	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileSubmit fromViewController:self userInfo:userInfo];
	
	if (self.profileView.nameField.text != [ATConnect sharedConnection].personName) {
		[ATConnect sharedConnection].personName = self.profileView.nameField.text;
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileName fromViewController:self userInfo:@{@"length": @(self.profileView.nameField.text.length)}];
	}

	if (self.profileView.emailField.text != [ATConnect sharedConnection].personEmailAddress) {
		[ATConnect sharedConnection].personEmailAddress = self.profileView.emailField.text;
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileEmail fromViewController:self userInfo:@{@"length": @(self.profileView.emailField.text.length), @"valid": @([ATUtilities emailAddressIsValid:self.profileView.emailField.text])}];
	}
	
	[[ATBackend sharedBackend] updatePersonIfNeeded];
	
	self.composeButtonItem.enabled = YES;
	self.neuMessageButtonItem.enabled = YES;
	[self updateState];
	
	if (self.state == ATMessageCenterStateEmpty) {
		[self.messageInputView.messageView becomeFirstResponder];
	} else {
		[self.view endEditing:YES];
		[self resizeFooterView:nil];
	}
}

- (IBAction)skipWho:(id)sender {
	NSDictionary *userInfo = @{@"required": @(self.interaction.profileRequired)};
	if ([sender isKindOfClass:[UIButton class]]) {
		userInfo = @{@"required": @(self.interaction.profileRequired), @"method": @"button", @"button_label": ((UIButton *)sender).titleLabel.text};
	}
	[self.interaction engage:ATInteractionMessageCenterEventLabelProfileClose fromViewController:sender userInfo:userInfo];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:ATMessageCenterDidSkipProfileKey];
	[self updateState];
	[self.view endEditing:YES];
	[self resizeFooterView:nil];
}

- (IBAction)showAbout:(id)sender {
	[self.navigationController pushViewController:[ATAboutViewController aboutViewControllerFromStoryboard] animated:YES];
}

#pragma mark - Private

- (void)saveDraft {
	NSString *message = self.messageInputView.messageView.text;
	if (message) {
		[[NSUserDefaults standardUserDefaults] setObject:message forKey:ATMessageCenterDraftMessageKey];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATMessageCenterDraftMessageKey];
	}

	[self.attachmentController saveDraft];
}

- (BOOL)isWhoValid {
	BOOL emailIsValid = [ATUtilities emailAddressIsValid:self.profileView.emailField.text];
	BOOL emailIsBlank = self.profileView.emailField.text.length == 0;
	
	if (self.interaction.profileRequired) {
		return emailIsValid;
	} else {
		return emailIsValid || emailIsBlank;
	}
}

- (void)updateState {
	if ([self shouldShowProfileViewBeforeComposing:YES]) {
		[self.interaction engage:ATInteractionMessageCenterEventLabelProfileOpen fromViewController:self userInfo:@{@"required": @(self.interaction.profileRequired), @"trigger": @"automatic"}];
		
		self.state = ATMessageCenterStateWhoCard;
	} else if (!self.dataSource.hasNonContextMessages) {
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
				// This indicates that the last message is a context message.
				self.state = ATMessageCenterStateReplied;
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
		BOOL toolbarHidden = NO;
		
		_state = state;
		
		self.navigationItem.leftBarButtonItem.enabled = YES;
		
		switch (state) {
			case ATMessageCenterStateEmpty:
				newFooter = self.messageInputView;
				toolbarHidden = YES;
				break;
				
			case ATMessageCenterStateComposing:
				newFooter = self.messageInputView;
				toolbarHidden = YES;
				break;
			
			case ATMessageCenterStateWhoCard:
				// Only focus profile view if appearing post-send.
				if (!self.interaction.profileRequired) {
					[self.profileView becomeFirstResponder];
				}
				self.navigationItem.leftBarButtonItem.enabled = NO;
				self.profileView.nameField.text = [ATConnect sharedConnection].personName;
				self.profileView.emailField.text = [ATConnect sharedConnection].personEmailAddress;
				toolbarHidden = YES;
				newFooter = self.profileView;
				break;
				
			case ATMessageCenterStateSending:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeEmpty;
				self.statusView.statusLabel.text = nil;
				break;
				
			case ATMessageCenterStateConfirmed:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeEmpty;
				self.statusView.statusLabel.text = self.interaction.statusBody;
				
				[self.interaction engage:ATInteractionMessageCenterEventLabelStatus fromViewController:self];
				break;
				
			case ATMessageCenterStateNetworkError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeNetworkError;
				self.statusView.statusLabel.text = self.interaction.networkErrorBody;
				
				[self.interaction engage:ATInteractionMessageCenterEventLabelNetworkError fromViewController:self];
				
				[self scrollToFooterView:nil];
				break;
				
			case ATMessageCenterStateHTTPError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeHTTPError;
				self.statusView.statusLabel.text = self.interaction.HTTPErrorBody;
				
				[self.interaction engage:ATInteractionMessageCenterEventLabelHTTPError fromViewController:self];

				[self scrollToFooterView:nil];
				break;
				
			case ATMessageCenterStateReplied:
				newFooter = nil;
				break;
				
			default:
				ATLogError(@"Invalid Message Center State: %d", state);
				break;
		}
		
		[self.navigationController setToolbarHidden:toolbarHidden animated:YES];
		
		if (newFooter != oldFooter) {
			newFooter.alpha = 0;
			newFooter.hidden = NO;
			
			if (oldFooter == self.messageInputView) {
				NSNumber *bodyLength = @(self.messageInputView.messageView.text.length);
				[self.interaction engage:ATInteractionMessageCenterEventLabelComposeClose fromViewController:self userInfo:@{@"body_length": bodyLength}];
			}
			
			if (newFooter == self.messageInputView) {
				[self.interaction engage:ATInteractionMessageCenterEventLabelComposeOpen fromViewController:self];
			}

			self.activeFooterView = newFooter;
			[self resizeFooterView:nil];

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

- (void)scrollToFooterView:(NSNotification *)notification {
	CGFloat footerSpace = [self.dataSource numberOfMessageGroups] > 0 ? self.tableView.sectionFooterHeight : 0;
	CGFloat verticalOffset = CGRectGetMaxY(self.rectOfLastMessage) + footerSpace;
	CGFloat verticalOffsetLimit;

	// A notification means a keyboard is involved, which uses different math
	if (notification) {
		CGRect keyboardRect = [self.view.window convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.tableView.superview];

		verticalOffsetLimit = self.tableView.contentSize.height - CGRectGetMinY(keyboardRect);
	} else {
		verticalOffsetLimit = self.tableView.contentSize.height - (CGRectGetHeight(self.tableView.bounds) - self.tableView.contentInset.bottom);
	}
	
	verticalOffsetLimit = fmax(0, verticalOffsetLimit);
	verticalOffset = fmin(verticalOffset, verticalOffsetLimit);
	CGPoint contentOffset = CGPointMake(0,  verticalOffset);
	
	if (notification) {
		[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
			self.tableView.contentOffset = contentOffset;
		}];
	} else {
		[self.tableView setContentOffset:contentOffset animated:YES];
	}
}

- (void)resizeFooterView:(NSNotification *)notification {
	CGFloat height = 0;
	
	if (self.state == ATMessageCenterStateComposing || self.state == ATMessageCenterStateEmpty) {
		CGRect keyboardRect;
		
		if (notification) {
			keyboardRect = [self.view.window convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:self.tableView.superview];
			
			// Available space is between the top of the keyboard and the bottom of the navigation bar
			height = CGRectGetMinY(keyboardRect) - self.tableView.contentInset.top;
			
			// Unless the top of the keyboard is below the (visible) toolbar, then subtract the toolbar height
			if (CGRectGetHeight(CGRectIntersection(keyboardRect, self.view.frame)) == 0 && !self.navigationController.toolbarHidden) {
					height -= CGRectGetHeight(self.navigationController.toolbar.bounds);
			}
		} else {
			// Workaround for weird race conditions on top layout guide and table view content inset
			CGFloat topBarHeight = fmax([self.topLayoutGuide length], self.tableView.contentInset.top);
			height = CGRectGetHeight(self.tableView.bounds) - topBarHeight;
		}
		
		// If there are no sent messages and the keyboard is off screen, fill the available space.
		if (!self.dataSource.hasNonContextMessages && (!notification || CGRectGetMinY(keyboardRect) >= CGRectGetMaxY(self.tableView.frame))) {
			height -= CGRectGetHeight(self.greetingView.bounds);
		}
	} else {
		height = CGRectGetHeight(self.activeFooterView.bounds);

		if (!self.navigationController.toolbarHidden) {
			height += CGRectGetHeight(self.navigationController.toolbar.bounds);
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

- (void)keyboardDidShow:(NSNotification *)notification {
	NSNumber *bodyLength = @(self.messageInputView.messageView.text.length);
	[self.interaction engage:ATInteractionMessageCenterEventLabelKeyboardOpen fromViewController:self userInfo:@{@"body_length": bodyLength}];
}

- (void)keyboardDidHide:(NSNotification *)notification {
	NSNumber *bodyLength = @(self.messageInputView.messageView.text.length);
	[self.interaction engage:ATInteractionMessageCenterEventLabelKeyboardClose fromViewController:self userInfo:@{@"body_length": bodyLength}];
}

- (NSString *)draftMessage {
	return [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey] ?: @"";
}

- (void)scrollToLastMessageAnimated:(BOOL)animated {
	if (self.state != ATMessageCenterStateEmpty && !(self.state == ATMessageCenterStateWhoCard && self.interaction.profileRequired && !self.dataSource.hasNonContextMessages)) {
		[self scrollToFooterView:nil];
	}
}

- (void)engageGreetingViewEventIfNecessary {
	BOOL greetingOnScreen = self.tableView.contentOffset.y < self.greetingView.bounds.size.height;
	if (self.greetingView.isOnScreen != greetingOnScreen) {
		if (greetingOnScreen) {
			[self.interaction engage:ATInteractionMessageCenterEventLabelGreetingMessage fromViewController:self];
		}
		self.greetingView.isOnScreen = greetingOnScreen;
	}
}

- (UIColor *)sentColor {
	return [UIColor colorWithRed:0.427 green:0.427 blue:0.447 alpha:1];
}

- (UIColor *)failedColor {
	return [UIColor colorWithRed:0.8 green:0.375 blue:0.412 alpha:1];
}

- (BOOL)shouldShowProfileViewBeforeComposing:(BOOL)beforeComposing {
	if ([ATUtilities emailAddressIsValid:[ATConnect sharedConnection].personEmailAddress]) {
		return NO;
	} else if (self.interaction.profileRequired) {
		return YES;
	} else if (self.interaction.profileRequested && !beforeComposing) {
		return ![[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidSkipProfileKey];
	} else {
		return NO;
	}
}

- (void)discardDraft {
	self.messageInputView.messageView.text = nil;
	[self.messageInputView.messageView resignFirstResponder];

	[self.attachmentController clear];
	[self.attachmentController resignFirstResponder];
	
	self.messageInputView.sendButton.enabled = [self sendButtonShouldBeEnabled];
	
	[self updateState];
	
	[self resizeFooterView:nil];
	
	// iOS 7 needs a (nano)sec to allow the keyboard to disappear before scrolling
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1)), dispatch_get_main_queue(), ^{
		[self scrollToLastMessageAnimated:YES];
	});
}

// Fix a bug where iOS7 resets the contentSize to zero sometimes
- (void)fixContentSize:(NSNotification *)notification {
	if (self.tableView.contentSize.height == 0) {
		self.tableView.tableFooterView = self.tableView.tableFooterView;
		[self scrollToFooterView:nil];
	}
}

@end
