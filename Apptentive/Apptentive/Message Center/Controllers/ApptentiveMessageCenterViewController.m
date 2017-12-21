//
//  ApptentiveMessageCenterViewController.m
//  Apptentive
//
//  Created by Frank Schmitt on 5/20/15.
//  Copyright (c) 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveAboutViewController.h"
#import "ApptentiveAttachButton.h"
#import "ApptentiveAttachmentCell.h"
#import "ApptentiveAttachmentController.h"
#import "ApptentiveCompoundMessageCell.h"
#import "ApptentiveIndexedCollectionView.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveMessageCenterContextMessageCell.h"
#import "ApptentiveMessageCenterGreetingView.h"
#import "ApptentiveMessageCenterInputView.h"
#import "ApptentiveMessageCenterMessageCell.h"
#import "ApptentiveMessageCenterProfileView.h"
#import "ApptentiveMessageCenterReplyCell.h"
#import "ApptentiveMessageCenterStatusView.h"
#import "ApptentiveNetworkImageIconView.h"
#import "ApptentiveNetworkImageView.h"
#import "ApptentiveProgressNavigationBar.h"
#import "ApptentiveUtilities.h"
#import "Apptentive_Private.h"
#import "ApptentiveBackend+Engagement.h"
#import <MobileCoreServices/UTCoreTypes.h>

#define HEADER_LABEL_HEIGHT 64.0
#define TEXT_VIEW_HORIZONTAL_INSET 12.0
#define TEXT_VIEW_VERTICAL_INSET 10.0
#define ATTACHMENT_MARGIN CGSizeMake(16.0, 15.0)
#define MINIMUM_INPUT_VIEW_HEIGHT 108.0

#define FOOTER_ANIMATION_DURATION 0.10

NS_ASSUME_NONNULL_BEGIN

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


@interface ApptentiveMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ApptentiveMessageCenterGreetingView *greetingView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterStatusView *statusView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterInputView *messageInputView;
@property (strong, nonatomic) IBOutlet ApptentiveMessageCenterProfileView *profileView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *composeButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *neuMessageButtonItem; // newMessageButtonItem

@property (strong, nonatomic) IBOutlet ApptentiveAttachmentController *attachmentController;

@property (readonly, nullable, nonatomic) NSIndexPath *indexPathOfLastMessage;

@property (assign, nonatomic) ATMessageCenterState state;

@property (weak, nonatomic) UIView *activeFooterView;

@property (assign, nonatomic) BOOL isSubsequentDisplay;

@property (readonly, nonatomic) NSString *trimmedMessage;
@property (readonly, nonatomic) BOOL messageComposerHasText;
@property (readonly, nonatomic) BOOL messageComposerHasAttachments;
@property (readonly, nonatomic) NSDictionary *bodyLengthDictionary;

@property (assign, nonatomic) CGRect lastKnownKeyboardRect;

@end


@implementation ApptentiveMessageCenterViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	if (self.viewModel != nil) {
		[self configureView];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollToFooterView:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeFooterView:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDraft) name:UIApplicationDidEnterBackgroundNotification object:nil];

	// Respond to dynamic type size changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateHeaderFooterTextSize:) name:UIContentSizeCategoryDidChangeNotification object:nil];

	[self.attachmentController addObserver:self forKeyPath:@"attachments" options:0 context:NULL];
	[self.attachmentController viewDidLoad];

	[self updateSendButtonEnabledStatus];

	self.tableView.estimatedRowHeight = 66.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

	ApptentiveProgressNavigationBar *navigationBar = (ApptentiveProgressNavigationBar *)self.navigationController.navigationBar;

	navigationBar.progressView.hidden = YES;
}

- (void)dealloc {
	self.tableView.delegate = nil;
	self.messageInputView.messageView.delegate = nil;
	self.profileView.nameField.delegate = nil;
	self.profileView.emailField.delegate = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	@try {
		// May get here before -viewDidLoad completes, in which case we aren't an observer.
		[self.attachmentController removeObserver:self forKeyPath:@"attachments"];
	} @catch (NSException *__unused exception) {
	}
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
	[self.greetingView traitCollectionDidChange:previousTraitCollection];

	[self resizeFooterView:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
	  // If the old cached keyboard rect overlaps the screen, assume it's moving off screen.
	  if (CGRectGetMinY(self.lastKnownKeyboardRect) <= CGRectGetHeight(self.view.bounds)) {
		  self.lastKnownKeyboardRect = CGRectMake(0, CGRectGetHeight(self.view.bounds), self.lastKnownKeyboardRect.size.width, self.lastKnownKeyboardRect.size.height);
	  }

	  [self resizeFooterView:nil];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context){
	}];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.lastKnownKeyboardRect = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth([UIScreen mainScreen].bounds), 20);

	if (self.attachmentController.active) {
		self.state = ATMessageCenterStateComposing;
		[self.attachmentController becomeFirstResponder];

		CGSize screenSize = [UIScreen mainScreen].bounds.size;
		CGSize drawerSize = self.attachmentController.inputView.bounds.size;
		self.lastKnownKeyboardRect = CGRectMake(0, screenSize.height - drawerSize.height, screenSize.width, drawerSize.height);
	} else if (self.messageComposerHasText || self.messageComposerHasAttachments) {
		self.state = ATMessageCenterStateComposing;
		[self.messageInputView.messageView becomeFirstResponder];
	} else if (self.isSubsequentDisplay == NO) {
		[self updateState];
	}
}

- (void)viewDidLayoutSubviews {
	if (self.isSubsequentDisplay == NO) {
		[self engageGreetingViewEventIfNecessary];
		[self scrollToLastMessageAnimated:NO];

		self.isSubsequentDisplay = YES;
	}
}

#pragma mark - View model

- (void)setViewModel:(ApptentiveMessageCenterViewModel *)viewModel {
	_viewModel.delegate = nil;

	_viewModel = viewModel;

	viewModel.delegate = self;

	if (self.isViewLoaded) {
		[self configureView];
	}
}

- (void)configureView {
	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelLaunch fromInteraction:self.viewModel.interaction fromViewController:self];

	[self.navigationController.toolbar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(compose:)]];

	self.navigationItem.rightBarButtonItem.title = ApptentiveLocalizedString(@"Close", @"Button that closes Message Center.");
	self.navigationItem.rightBarButtonItem.accessibilityHint = ApptentiveLocalizedString(@"Closes Message Center.", @"Accessibility hint for 'close' button");

	self.navigationItem.title = self.viewModel.title;

	self.tableView.separatorColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];
	self.tableView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorCollectionBackground];

	self.greetingView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorHeaderBackground];
	self.greetingView.borderView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];

	self.greetingView.titleLabel.text = self.viewModel.greetingTitle;
	self.greetingView.titleLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleHeaderTitle];

	self.greetingView.messageLabel.text = self.viewModel.greetingBody;
	self.greetingView.messageLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleHeaderMessage];

	self.greetingView.imageView.imageURL = self.viewModel.greetingImageURL;

	self.greetingView.aboutButton.hidden = !self.viewModel.branding;
	self.greetingView.aboutButton.tintColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleHeaderMessage];
	self.greetingView.isOnScreen = NO;

	[self updateHeaderFooterTextSize:nil];

	[self.greetingView.aboutButton setImage:[[ApptentiveUtilities imageNamed:@"at_info"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	self.greetingView.aboutButton.accessibilityLabel = ApptentiveLocalizedString(@"About Apptentive", @"Accessibility label for 'show about' button");
	self.greetingView.aboutButton.accessibilityHint = ApptentiveLocalizedString(@"Displays information about this feature.", @"Accessibilty hint for 'show about' button");

	self.statusView.mode = ATMessageCenterStatusModeEmpty;

	self.messageInputView.messageView.text = self.viewModel.draftMessage ?: @"";
	self.messageInputView.messageView.textContainerInset = UIEdgeInsetsMake(TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET, TEXT_VIEW_VERTICAL_INSET);
	[self.messageInputView.clearButton setImage:[[ApptentiveUtilities imageNamed:@"at_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

	self.messageInputView.messageView.accessibilityHint = [NSString stringWithFormat:@"%@. %@", self.viewModel.composerTitle, self.viewModel.composerPlaceholderText];
	self.messageInputView.placeholderLabel.text = self.viewModel.composerPlaceholderText;
	self.messageInputView.placeholderLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder];

	self.messageInputView.placeholderLabel.hidden = self.messageInputView.messageView.text.length > 0;

	self.messageInputView.titleLabel.text = self.viewModel.composerTitle;
	self.neuMessageButtonItem.title = self.viewModel.composerTitle;
	[self.messageInputView.sendButton setTitle:self.viewModel.composerSendButtonTitle forState:UIControlStateNormal];

	self.messageInputView.sendButton.accessibilityHint = ApptentiveLocalizedString(@"Sends the message.", @"Accessibility hint for 'send' button");

	self.messageInputView.clearButton.accessibilityLabel = ApptentiveLocalizedString(@"Discard", @"Accessibility label for 'discard' button");
	self.messageInputView.clearButton.accessibilityHint = ApptentiveLocalizedString(@"Discards the message.", @"Accessibility hint for 'discard' button");

	[self.messageInputView.attachButton setImage:[ApptentiveUtilities imageNamed:@"at_attach"] forState:UIControlStateNormal];
	[self.messageInputView.attachButton setTitleColor:[self.viewModel.styleSheet colorForStyle:ApptentiveColorBackground] forState:UIControlStateNormal];

	self.messageInputView.attachButton.accessibilityLabel = ApptentiveLocalizedString(@"Attach", @"Accessibility label for 'attach' button");
	self.messageInputView.attachButton.accessibilityHint = ApptentiveLocalizedString(@"Attaches a photo or screenshot", @"Accessibility hint for 'attach'");

	self.messageInputView.containerView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorBackground];
	self.messageInputView.borderColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];
	self.messageInputView.messageView.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleTextInput];
	self.messageInputView.messageView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputBackground];
	self.messageInputView.titleLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleButton];

	self.statusView.statusLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleMessageCenterStatus];
	self.statusView.imageView.tintColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleMessageCenterStatus];

	if (self.viewModel.profileRequested) {
		UIBarButtonItem *profileButtonItem = [[UIBarButtonItem alloc] initWithImage:[ApptentiveUtilities imageNamed:@"at_account"] landscapeImagePhone:[ApptentiveUtilities imageNamed:@"at_account"] style:UIBarButtonItemStylePlain target:self action:@selector(showWho:)];
		profileButtonItem.accessibilityLabel = ApptentiveLocalizedString(@"Profile", @"Accessibility label for 'edit profile' button");
		profileButtonItem.accessibilityHint = ApptentiveLocalizedString(@"Allows editing of your name and email.", @"Accessibility hint for 'edit profile' button");
		self.navigationItem.leftBarButtonItem = profileButtonItem;

		self.profileView.containerView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorBackground];
		self.profileView.titleLabel.text = self.viewModel.profileInitialTitle;
		self.profileView.titleLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleButton];
		self.profileView.requiredLabel.text = self.viewModel.profileInitialEmailExplanation;
		self.profileView.requiredLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleSurveyInstructions];
		[self.profileView.saveButton setTitle:self.viewModel.profileInitialSaveButtonTitle forState:UIControlStateNormal];
		[self.profileView.skipButton setTitle:self.viewModel.profileInitialSkipButtonTitle forState:UIControlStateNormal];
		self.profileView.skipButton.hidden = self.viewModel.profileRequired;
		[self validateWho:self];
		self.profileView.borderColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorSeparator];

		self.profileView.nameField.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputBackground];
		self.profileView.emailField.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputBackground];

		NSDictionary *placeholderAttributes = @{NSForegroundColorAttributeName: [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder]};
		self.profileView.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.viewModel.profileInitialNamePlaceholder attributes:placeholderAttributes];
		self.profileView.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.viewModel.profileInitialEmailPlaceholder attributes:placeholderAttributes];

		if (self.viewModel.profileRequired && [self shouldShowProfileViewBeforeComposing:YES]) {
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
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.viewModel numberOfMessageGroups];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.viewModel numberOfMessagesInGroup:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.viewModel markAsReadMessageAtIndexPath:indexPath];

	UITableViewCell<ApptentiveMessageCenterCell> *cell;
	ATMessageCenterMessageType type = [self.viewModel cellTypeAtIndexPath:indexPath];

	if (type == ATMessageCenterMessageTypeMessage || type == ATMessageCenterMessageTypeCompoundMessage) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundMessage ? @"CompoundMessage" : @"Message";
		ApptentiveMessageCenterMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

		switch ([self.viewModel statusOfMessageAtIndexPath:indexPath]) {
			case ATMessageCenterMessageStatusHidden:
				messageCell.statusLabelHidden = YES;
				messageCell.layer.borderWidth = 0;
				break;
			case ATMessageCenterMessageStatusFailed:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
				messageCell.layer.borderColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorFailure].CGColor;
				messageCell.statusLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorFailure];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Failed", @"Message failed to send.");
				break;
			case ATMessageCenterMessageStatusSending:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleMessageStatus];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Sending…", @"Message is sending.");
				break;
			case ATMessageCenterMessageStatusSent:
				messageCell.statusLabelHidden = NO;
				messageCell.layer.borderWidth = 0;
				messageCell.statusLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleMessageStatus];
				messageCell.statusLabel.text = ApptentiveLocalizedString(@"Sent", @"Message sent successfully");
				break;
		}

		messageCell.statusLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleMessageStatus];

		cell = messageCell;
	} else if (type == ATMessageCenterMessageTypeReply || type == ATMessageCenterMessageTypeCompoundReply) {
		NSString *cellIdentifier = type == ATMessageCenterMessageTypeCompoundReply ? @"CompoundReply" : @"Reply";
		ApptentiveMessageCenterReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];

		replyCell.supportUserImageView.imageURL = [self.viewModel imageURLOfSenderAtIndexPath:indexPath];

		replyCell.messageLabel.text = [self.viewModel textOfMessageAtIndexPath:indexPath];
		replyCell.senderLabel.text = [self.viewModel senderOfMessageAtIndexPath:indexPath];

		cell = replyCell;
	} else { // Message cell
		ApptentiveMessageCenterContextMessageCell *contextMessageCell = [tableView dequeueReusableCellWithIdentifier:@"ContextMessage" forIndexPath:indexPath];

		cell = contextMessageCell;
	}

	cell.messageLabel.font = [self.viewModel.styleSheet fontForStyle:UIFontTextStyleBody];
	cell.messageLabel.textColor = [self.viewModel.styleSheet colorForStyle:UIFontTextStyleBody];
	cell.messageLabel.text = [self.viewModel textOfMessageAtIndexPath:indexPath];

	if (type == ATMessageCenterMessageTypeCompoundMessage || type == ATMessageCenterMessageTypeCompoundReply) {
		UITableViewCell<ApptentiveMessageCenterCompoundCell> *compoundCell = (ApptentiveCompoundMessageCell *)cell;

		compoundCell.collectionView.index = indexPath.section;
		compoundCell.collectionView.dataSource = self;
		compoundCell.collectionView.delegate = self;
		[compoundCell.collectionView reloadData];
		compoundCell.collectionView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorBackground];

		UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)compoundCell.collectionView.collectionViewLayout;
		layout.sectionInset = UIEdgeInsetsMake(ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width, ATTACHMENT_MARGIN.height, ATTACHMENT_MARGIN.width);
		layout.minimumInteritemSpacing = ATTACHMENT_MARGIN.width;
		layout.itemSize = [ApptentiveAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN];

		compoundCell.collectionViewHeightConstraint.constant = ATTACHMENT_MARGIN.height * 2 + layout.itemSize.height;

		compoundCell.messageLabelHidden = compoundCell.messageLabel.text.length == 0;
	}

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	CGFloat height = self.tableView.sectionHeaderHeight;

	if ([self.viewModel shouldShowDateForMessageGroupAtIndex:section]) {
		height += HEADER_LABEL_HEIGHT;
	}

	return height;
}

#pragma mark Table view delegate

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (![self.viewModel shouldShowDateForMessageGroupAtIndex:section]) {
		return nil;
	}

	UITableViewHeaderFooterView *header = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Date"];

	if (header == nil) {
		header = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"Date"];
	}

	header.textLabel.text = [self.viewModel titleForHeaderInSection:section];

	return header;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
	UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
	headerView.textLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleMessageDate];
	headerView.textLabel.textColor = [self.viewModel.styleSheet colorForStyle:ApptentiveTextStyleMessageDate];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ([self.viewModel cellTypeAtIndexPath:indexPath]) {
		case ATMessageCenterMessageTypeCompoundMessage:
			((id<ApptentiveMessageCenterCompoundCell>)cell).collectionView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorMessageBackground];
		// Fall through
		case ATMessageCenterMessageTypeMessage:
			cell.contentView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorMessageBackground];
			cell.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorMessageBackground];
			break;

		case ATMessageCenterMessageTypeCompoundReply:
			((id<ApptentiveMessageCenterCompoundCell>)cell).collectionView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorReplyBackground];
		// Fall through
		case ATMessageCenterMessageTypeReply:
			cell.contentView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorReplyBackground];
			cell.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorReplyBackground];
			break;

		case ATMessageCenterMessageTypeContextMessage:
			cell.contentView.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorContextBackground];
			cell.backgroundColor = [self.viewModel.styleSheet colorForStyle:ApptentiveColorContextBackground];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
	return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
	if (indexPath) {
		[[UIPasteboard generalPasteboard] setValue:[self.viewModel textOfMessageAtIndexPath:indexPath] forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];
	}
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self engageGreetingViewEventIfNecessary];
}

#pragma mark Message center view model delegate

- (void)viewModelWillChangeContent:(ApptentiveMessageCenterViewModel *)viewModel {
	[self.tableView beginUpdates];
}

- (void)viewModelDidChangeContent:(ApptentiveMessageCenterViewModel *)viewModel {
	[self updateStatusOfVisibleCells];

	@try {
		[self.tableView endUpdates];
	} @catch (NSException *exc) {
		ApptentiveAssertTrue(NO, @"Exception when updating table view: %@", exc);
	}

	if (self.state != ATMessageCenterStateWhoCard && self.state != ATMessageCenterStateComposing) {
		ATMessageCenterState oldState = self.state;

		[self updateState];

		[self resizeFooterView:nil];
		[self scrollToLastMessageAnimated:YES];

		if (self.state == ATMessageCenterStateSending && oldState == ATMessageCenterStateConfirmed) {
			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.statusView.statusLabel);

			if (self.viewModel.statusBody.length > 0) {
				UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.viewModel.statusBody);
			}
		}
	}
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didInsertMessageAtIndex:(NSInteger)index {
	[self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didUpdateMessageAtIndex:(NSInteger)index {
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didDeleteMessageAtIndex:(NSInteger)index {
	[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];
	attachmentCell.progressView.hidden = YES;

	[collectionView reloadItemsAtIndexPaths:@[collectionViewIndexPath]];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel attachmentDownloadAtIndexPath:(NSIndexPath *)indexPath didProgress:(float)progress {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = NO;
	[attachmentCell.progressView setProgress:progress animated:YES];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel didFailToLoadAttachmentThumbnailAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error {
	ApptentiveCompoundMessageCell *cell = (ApptentiveCompoundMessageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
	ApptentiveIndexedCollectionView *collectionView = cell.collectionView;
	NSIndexPath *collectionViewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
	ApptentiveAttachmentCell *attachmentCell = (ApptentiveAttachmentCell *)[collectionView cellForItemAtIndexPath:collectionViewIndexPath];

	attachmentCell.progressView.hidden = YES;
	attachmentCell.progressView.progress = 0;

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ApptentiveLocalizedString(@"Unable to Download Attachment", @"Attachment download failed alert title") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
	[alertController addAction:[UIAlertAction actionWithTitle:ApptentiveLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];

	[self presentViewController:alertController animated:YES completion:nil];
}

- (void)messageCenterViewModel:(ApptentiveMessageCenterViewModel *)viewModel messageProgressDidChange:(float)progress {
	ApptentiveProgressNavigationBar *navigationBar = (ApptentiveProgressNavigationBar *)self.navigationController.navigationBar;

	navigationBar.progressView.hidden = progress == 0;

	BOOL animated = navigationBar.progressView.progress < progress;
	[navigationBar.progressView setProgress:progress animated:animated];
}

#pragma mark Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ApptentiveIndexedCollectionView *)collectionView).index];

	if ([self.viewModel canPreviewAttachmentAtIndexPath:attachmentIndexPath]) {
		QLPreviewController *previewController = [[QLPreviewController alloc] init];

		previewController.dataSource = [self.viewModel previewDataSourceAtIndex:((ApptentiveIndexedCollectionView *)collectionView).index];
		previewController.currentPreviewItemIndex = indexPath.row;

		[self.navigationController pushViewController:previewController animated:YES];
	} else {
		[self.viewModel downloadAttachmentAtIndexPath:attachmentIndexPath];
	}
}

#pragma mark Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self.viewModel numberOfAttachmentsForMessageAtIndex:((ApptentiveIndexedCollectionView *)collectionView).index];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ApptentiveAttachmentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Attachment" forIndexPath:indexPath];
	NSIndexPath *attachmentIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:((ApptentiveIndexedCollectionView *)collectionView).index];

	cell.usePlaceholder = [self.viewModel shouldUsePlaceholderForAttachmentAtIndexPath:attachmentIndexPath];
	cell.imageView.image = [self.viewModel imageForAttachmentAtIndexPath:attachmentIndexPath size:[ApptentiveAttachmentCell sizeForScreen:[UIScreen mainScreen] withMargin:ATTACHMENT_MARGIN]];
	cell.extensionLabel.text = [self.viewModel extensionForAttachmentAtIndexPath:attachmentIndexPath];

	return cell;
}

#pragma mark - Text view delegate

- (void)textViewDidChange:(UITextView *)textView {
	[self updateSendButtonEnabledStatus];
	self.messageInputView.placeholderLabel.hidden = textView.text.length > 0;

	// Fix bug where text view doesn't scroll far enough down
	// Adapted from http://stackoverflow.com/a/19277383/27951
	CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
	CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top);
	if (overflow > 0) {
		// Scroll caret to visible area
		CGPoint offset = textView.contentOffset;
		offset.y += overflow + textView.textContainerInset.bottom;

		// Cannot animate with setContentOffset:animated: or caret will not appear
		[UIView animateWithDuration:.2
						 animations:^{
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

#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
	[self.attachmentController resignFirstResponder];

	[self saveDraft];

	[self.viewModel stop];

	UIViewController *presentingViewController = self.presentingViewController;

	[self dismissViewControllerAnimated:YES
							 completion:^{
							   [Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelClose fromInteraction:self.viewModel.interaction fromViewController:presentingViewController];
							 }];

	self.interactionController = nil;
}

- (IBAction)send:(id)sender {
	[self.viewModel sendMessage:self.trimmedMessage withAttachments:self.attachmentController.attachments];

	[self.attachmentController clear];
	[self.attachmentController resignFirstResponder];
	self.attachmentController.active = NO;

	if ([self shouldShowProfileViewBeforeComposing:NO]) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileOpen
						  fromInteraction:self.viewModel.interaction
					   fromViewController:self
								 userInfo:@{ @"required": @(self.viewModel.profileRequired),
									  @"trigger": @"automatic" }];

		self.state = ATMessageCenterStateWhoCard;
	} else {
		[self.messageInputView.messageView resignFirstResponder];
		[self updateState];
	}

	self.messageInputView.messageView.text = @"";
	[self updateSendButtonEnabledStatus];
}

- (IBAction)compose:(id)sender {
	self.state = ATMessageCenterStateComposing;
	[self.messageInputView.messageView becomeFirstResponder];
}

- (IBAction)clear:(UIButton *)sender {
	if (!self.messageComposerHasText && !self.messageComposerHasAttachments) {
		[self discardDraft];
		return;
	}

	BOOL cancelReturnsToComposer = !self.attachmentController.active;

	[self.messageInputView.messageView resignFirstResponder];

	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.viewModel.composerCloseConfirmBody message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	[alertController addAction:[UIAlertAction actionWithTitle:self.viewModel.composerCloseCancelButtonTitle
														style:UIAlertActionStyleCancel
													  handler:^(UIAlertAction *_Nonnull action) {
														if (cancelReturnsToComposer) {
															[self.messageInputView.messageView becomeFirstResponder];
														} else {
															[self.attachmentController becomeFirstResponder];
														}
													  }]];
	[alertController addAction:[UIAlertAction actionWithTitle:self.viewModel.composerCloseDiscardButtonTitle
														style:UIAlertActionStyleDestructive
													  handler:^(UIAlertAction *action) {
														[self discardDraft];
													  }]];

	[self presentViewController:alertController animated:YES completion:nil];
	alertController.popoverPresentationController.sourceView = sender.superview;
	alertController.popoverPresentationController.sourceRect = sender.frame;
}

- (IBAction)showWho:(id)sender {
	self.profileView.mode = ATMessageCenterProfileModeFull;

	self.profileView.skipButton.hidden = NO;
	self.profileView.titleLabel.text = self.viewModel.profileEditTitle;

	NSDictionary *placeholderAttributes = @{NSForegroundColorAttributeName: [self.viewModel.styleSheet colorForStyle:ApptentiveColorTextInputPlaceholder]};
	self.profileView.nameField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.viewModel.profileEditNamePlaceholder attributes:placeholderAttributes];
	self.profileView.emailField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.viewModel.profileEditEmailPlaceholder attributes:placeholderAttributes];

	[self.profileView.saveButton setTitle:self.viewModel.profileEditSaveButtonTitle forState:UIControlStateNormal];
	[self.profileView.skipButton setTitle:self.viewModel.profileEditSkipButtonTitle forState:UIControlStateNormal];

	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileOpen
					  fromInteraction:self.viewModel.interaction
				   fromViewController:self
							 userInfo:@{ @"required": @(self.viewModel.profileRequired),
								  @"trigger": @"button" }];

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
	[userInfo setObject:@(self.viewModel.profileRequired) forKey:@"required"];
	if (buttonLabel) {
		[userInfo setObject:buttonLabel forKey:@"button_label"];
	}

	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileSubmit fromInteraction:self.viewModel.interaction fromViewController:self userInfo:userInfo];

	if (self.profileView.nameField.text != self.viewModel.personName) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileName fromInteraction:self.viewModel.interaction fromViewController:self userInfo:@{ @"length": @(self.profileView.nameField.text.length) }];
	}

	if (self.profileView.emailField.text != self.viewModel.personEmailAddress) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileEmail
						  fromInteraction:self.viewModel.interaction
					   fromViewController:self
								 userInfo:@{ @"length": @(self.profileView.emailField.text.length),
									  @"valid": @([ApptentiveUtilities emailAddressIsValid:self.profileView.emailField.text]) }];
	}

	[self.viewModel setPersonName:self.profileView.nameField.text emailAddress:self.profileView.emailField.text];

	self.composeButtonItem.enabled = YES;
	self.neuMessageButtonItem.enabled = YES;
	[self updateState];

	if (self.state == ATMessageCenterStateEmpty) {
		[self.messageInputView.messageView becomeFirstResponder];
	} else {
		[self.view endEditing:YES];
		[self resizeFooterView:nil];
	}

	UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Profile Saved");
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.leftBarButtonItem);
}

- (IBAction)skipWho:(id)sender {
	NSDictionary *userInfo = @{ @"required": @(self.viewModel.profileRequired) };
	if ([sender isKindOfClass:[UIButton class]]) {
		userInfo = @{ @"required": @(self.viewModel.profileRequired),
			@"method": @"button",
			@"button_label": ((UIButton *)sender).titleLabel.text };
	}
	[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileClose fromInteraction:self.viewModel.interaction fromViewController:sender userInfo:userInfo];

	self.viewModel.didSkipProfile = YES;

	[self updateState];
	[self.view endEditing:YES];
	[self resizeFooterView:nil];

	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.leftBarButtonItem);
}

- (IBAction)showAbout:(id)sender {
	[(ApptentiveNavigationController *)self.navigationController pushAboutApptentiveViewController];
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString *, id> *)change context:(nullable void *)context {
	[self updateSendButtonEnabledStatus];
}

#pragma mark - Private

- (void)updateStatusOfVisibleCells {
	NSMutableArray *indexPathsToReload = [NSMutableArray array];
	for (UITableViewCell *cell in self.tableView.visibleCells) {
		if ([cell isKindOfClass:[ApptentiveMessageCenterMessageCell class]]) {
			ApptentiveMessageCenterMessageCell *messageCell = (ApptentiveMessageCenterMessageCell *)cell;
			NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
			ApptentiveAssertNotNil(indexPath, @"Index path is nil for cell: %@", cell);
			if (indexPath == nil) {
				continue;
			}

			BOOL shouldHideStatus = [self.viewModel statusOfMessageAtIndexPath:indexPath] == ATMessageCenterMessageStatusHidden;

			if (messageCell.statusLabelHidden != shouldHideStatus) {
				[indexPathsToReload addObject:indexPath];
			}
		}
	}

	@try {
		[self.tableView reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationFade];
	} @catch (NSException *exception) {
		ApptentiveAssertTrue(NO, @"Exception when reloading row in table view");
	}
}

- (NSDictionary *)bodyLengthDictionary {
	return @{ @"body_length": @(self.messageInputView.messageView.text.length) };
}

- (NSString *)trimmedMessage {
	return [self.messageInputView.messageView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)messageComposerHasText {
	return self.trimmedMessage.length > 0;
}

- (BOOL)messageComposerHasAttachments {
	return self.attachmentController.attachments.count > 0;
}

- (void)updateSendButtonEnabledStatus {
	self.messageInputView.sendButton.enabled = self.messageComposerHasText || self.messageComposerHasAttachments;
}

- (void)saveDraft {
	if (self.messageComposerHasText) {
		self.viewModel.draftMessage = self.trimmedMessage;
	} else {
		self.viewModel.draftMessage = nil;
	}

	[self.attachmentController saveDraft];
}

- (BOOL)isWhoValid {
	BOOL emailIsValid = [ApptentiveUtilities emailAddressIsValid:self.profileView.emailField.text];
	BOOL emailIsBlank = self.profileView.emailField.text.length == 0;

	if (self.viewModel.profileRequired) {
		return emailIsValid;
	} else {
		return emailIsValid || emailIsBlank;
	}
}

- (void)updateState {
	if ([self shouldShowProfileViewBeforeComposing:YES]) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelProfileOpen
						  fromInteraction:self.viewModel.interaction
					   fromViewController:self
								 userInfo:@{ @"required": @(self.viewModel.profileRequired),
									  @"trigger": @"automatic" }];

		self.state = ATMessageCenterStateWhoCard;
	} else if (!self.viewModel.hasNonContextMessages) {
		self.state = ATMessageCenterStateEmpty;
	} else if (self.viewModel.lastMessageIsReply) {
		self.state = ATMessageCenterStateReplied;
	} else {
		BOOL networkIsUnreachable = !self.viewModel.networkIsReachable;

		switch (self.viewModel.lastUserMessageState) {
			case ApptentiveMessageStateSent:
				self.state = ATMessageCenterStateConfirmed;
				break;
			case ApptentiveMessageStateFailedToSend:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateHTTPError;
				break;
			case ApptentiveMessageStatePending:
			case ApptentiveMessageStateWaiting:
			case ApptentiveMessageStateSending:
				self.state = networkIsUnreachable ? ATMessageCenterStateNetworkError : ATMessageCenterStateSending;
				break;
			default:
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
				if ([self.attachmentController isFirstResponder]) {
					[self.attachmentController resignFirstResponder];
					[self.profileView becomeFirstResponder];
				}
				if (!self.viewModel.profileRequired) {
					[self.profileView becomeFirstResponder];
				}
				self.navigationItem.leftBarButtonItem.enabled = NO;
				self.profileView.nameField.text = self.viewModel.personName;
				self.profileView.emailField.text = self.viewModel.personEmailAddress;
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
				self.statusView.statusLabel.text = self.viewModel.statusBody;

				[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelStatus fromInteraction:self.viewModel.interaction fromViewController:self];
				break;

			case ATMessageCenterStateNetworkError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeNetworkError;
				self.statusView.statusLabel.text = self.viewModel.networkErrorBody;

				[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelNetworkError fromInteraction:self.viewModel.interaction fromViewController:self];

				[self scrollToFooterView:nil];
				break;

			case ATMessageCenterStateHTTPError:
				newFooter = self.statusView;
				self.statusView.mode = ATMessageCenterStatusModeHTTPError;
				self.statusView.statusLabel.text = self.viewModel.HTTPErrorBody;

				[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelHTTPError fromInteraction:self.viewModel.interaction fromViewController:self];

				[self scrollToFooterView:nil];
				break;

			case ATMessageCenterStateReplied:
				newFooter = nil;
				break;

			default:
				ApptentiveLogError(@"Invalid Message Center State: %d", state);
				break;
		}

		[self.navigationController setToolbarHidden:toolbarHidden animated:YES];

		if (newFooter != oldFooter) {
			newFooter.alpha = 0;
			newFooter.hidden = NO;

			if (oldFooter == self.messageInputView) {
				[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelComposeClose fromInteraction:self.viewModel.interaction fromViewController:self userInfo:self.bodyLengthDictionary];
			}

			if (newFooter == self.messageInputView) {
				[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelComposeOpen fromInteraction:self.viewModel.interaction fromViewController:self];
			}

			self.activeFooterView = newFooter;
			[self resizeFooterView:nil];

			[UIView animateWithDuration:0.25
				animations:^{
				  newFooter.alpha = 1;
				  oldFooter.alpha = 0;
				}
				completion:^(BOOL finished) {
				  oldFooter.hidden = YES;
				}];
		}
	}
}

- (nullable NSIndexPath *)indexPathOfLastMessage {
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

- (void)scrollToFooterView:(nullable NSNotification *)notification {
	[self.tableView scrollToRowAtIndexPath:self.indexPathOfLastMessage atScrollPosition:UITableViewScrollPositionTop animated:NO];
	[self.tableView layoutIfNeeded];

	if (notification) {
		self.lastKnownKeyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	}

	CGRect localKeyboardRect = self.view.window ? [self.view.window convertRect:self.lastKnownKeyboardRect toView:self.tableView.superview] : self.lastKnownKeyboardRect;

	CGFloat footerSpace = [self.viewModel numberOfMessageGroups] > 0 ? self.tableView.sectionFooterHeight : 0;
	CGFloat verticalOffset = CGRectGetMaxY(self.rectOfLastMessage) + footerSpace;
	CGFloat toolbarHeight = self.navigationController.toolbarHidden ? 0 : CGRectGetHeight(self.navigationController.toolbar.bounds);

	CGFloat heightOfVisibleView = fmin(CGRectGetMinY(localKeyboardRect), CGRectGetHeight(self.view.bounds) - toolbarHeight);

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		CGFloat homeAreaHeight = self.tableView.safeAreaInsets.bottom - self.tableView.contentInset.bottom;

		if (CGRectGetMinY(localKeyboardRect) >= CGRectGetMaxY(self.tableView.bounds)) {
			// If keyboard is hidden, save room for the home "button"
			heightOfVisibleView -= homeAreaHeight;
		}
	}
#endif

	CGFloat verticalOffsetMaximum = fmax(self.topLayoutGuide.length * -1, self.tableView.contentSize.height - heightOfVisibleView);

	verticalOffset = fmin(verticalOffset, verticalOffsetMaximum);
	CGPoint contentOffset = CGPointMake(0, verticalOffset);

	CGFloat duration = notification ? [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] : 0.25;
	[UIView animateWithDuration:duration
					 animations:^{
					   self.tableView.contentOffset = contentOffset;
					 }];
}

- (void)resizeFooterView:(nullable NSNotification *)notification {
	CGFloat height = 0;

	if (self.state == ATMessageCenterStateComposing || self.state == ATMessageCenterStateEmpty) {
		if (notification) {
			self.lastKnownKeyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
		}

		CGRect localKeyboardRect = self.view.window ? [self.view.window convertRect:self.lastKnownKeyboardRect toView:self.tableView.superview] : self.lastKnownKeyboardRect;

		CGFloat topContentInset = self.tableView.contentInset.top;
		CGFloat homeAreaInset = 0;
#ifdef __IPHONE_11_0
		if (@available(iOS 11.0, *)) {
			topContentInset = fmax(self.tableView.layoutMargins.top, self.tableView.safeAreaInsets.top);
			homeAreaInset = fmax(0, self.tableView.safeAreaInsets.bottom - self.tableView.contentInset.bottom);
		}
#endif

		// Available space is between the top of the keyboard and the bottom of the navigation bar
		height = fmin(CGRectGetMinY(localKeyboardRect), CGRectGetHeight(self.view.bounds)) - topContentInset;

		// Unless the top of the keyboard is below the (visible) toolbar, then subtract the toolbar height
		if (CGRectGetHeight(CGRectIntersection(localKeyboardRect, self.view.frame)) == 0 && !self.navigationController.toolbarHidden) {
			height -= CGRectGetHeight(self.navigationController.toolbar.bounds);
		}

		// In an empty state (possibly w/ context message) when the keyboard is not visible, leave room for greeting view + context message
		if (!self.viewModel.hasNonContextMessages && CGRectGetMinY(localKeyboardRect) >= CGRectGetMaxY(self.tableView.frame)) {
			if (self.viewModel.numberOfMessageGroups == 0) {
				height -= CGRectGetHeight(self.greetingView.bounds);
			} else {
				height -= CGRectGetMaxY(self.rectOfLastMessage) + self.tableView.sectionFooterHeight;
			}

			height -= homeAreaInset;
		}

		// But don't shrink the thing until it's unusably small on e.g. 4S devices
		height = fmax(height, MINIMUM_INPUT_VIEW_HEIGHT);
	} else {
		height = CGRectGetHeight(self.activeFooterView.bounds);

		if (!self.navigationController.toolbarHidden) {
			height += CGRectGetHeight(self.navigationController.toolbar.bounds);
		}
	}

	CGRect frame = self.tableView.tableFooterView.frame;

	frame.size.height = height;

	[UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
					 animations:^{
					   self.tableView.tableFooterView.frame = frame;
					   [self.tableView.tableFooterView layoutIfNeeded];
					   self.tableView.tableFooterView = self.tableView.tableFooterView;
					 }];
}

- (void)keyboardDidShow:(NSNotification *)notification {
	if (!self.attachmentController.active) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelKeyboardOpen fromInteraction:self.viewModel.interaction fromViewController:self userInfo:self.bodyLengthDictionary];
	}
}

- (void)keyboardDidHide:(NSNotification *)notification {
	if (!self.attachmentController.active) {
		[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelKeyboardClose fromInteraction:self.viewModel.interaction fromViewController:self userInfo:self.bodyLengthDictionary];
	}
}

- (void)scrollToLastMessageAnimated:(BOOL)animated {
	[self scrollToFooterView:nil];
}

- (void)engageGreetingViewEventIfNecessary {
	BOOL greetingOnScreen = self.tableView.contentOffset.y < self.greetingView.bounds.size.height;
	if (self.greetingView.isOnScreen != greetingOnScreen) {
		if (greetingOnScreen) {
			[Apptentive.shared.backend engage:ATInteractionMessageCenterEventLabelGreetingMessage fromInteraction:self.viewModel.interaction fromViewController:self];
		}
		self.greetingView.isOnScreen = greetingOnScreen;
	}
}

- (BOOL)shouldShowProfileViewBeforeComposing:(BOOL)beforeComposing {
	if ([ApptentiveUtilities emailAddressIsValid:self.viewModel.personEmailAddress]) {
		return NO;
	} else if (self.viewModel.profileRequired) {
		return YES;
	} else if (self.viewModel.profileRequested && !beforeComposing) {
		return !self.viewModel.didSkipProfile;
	} else {
		return NO;
	}
}

- (void)discardDraft {
	self.messageInputView.messageView.text = nil;
	[self.messageInputView.messageView resignFirstResponder];

	[self.attachmentController clear];
	[self.attachmentController resignFirstResponder];

	[self updateSendButtonEnabledStatus];
	[self updateState];

	[self resizeFooterView:nil];

	[self scrollToLastMessageAnimated:YES];
}

- (void)updateHeaderFooterTextSize:(nullable NSNotification *)notification {
	self.greetingView.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleHeaderTitle];
	self.greetingView.messageLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleHeaderMessage];

	self.messageInputView.sendButton.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleDoneButton];
	self.messageInputView.placeholderLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];

	self.messageInputView.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.messageInputView.messageView.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];

	self.statusView.statusLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleMessageCenterStatus];

	self.profileView.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.profileView.saveButton.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleDoneButton];
	self.profileView.skipButton.titleLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleButton];
	self.profileView.requiredLabel.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleSurveyInstructions];
	self.profileView.nameField.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
	self.profileView.emailField.font = [self.viewModel.styleSheet fontForStyle:ApptentiveTextStyleTextInput];
}

@end

NS_ASSUME_NONNULL_END
