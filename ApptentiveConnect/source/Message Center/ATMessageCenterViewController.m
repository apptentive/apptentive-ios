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

@interface ATMessageCenterViewController ()

@property (weak, nonatomic) IBOutlet ATMessageCenterGreetingView *greetingView;
@property (weak, nonatomic) IBOutlet ATMessageCenterConfirmationView *confirmationView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel *poweredByLabel;
@property (weak, nonatomic) IBOutlet UIImageView *poweredByImageView;

@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UITextView *messageView;
@property (nonatomic, readwrite, retain) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, strong) ATMessageCenterDataSource *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (weak, nonatomic) NSLayoutConstraint *inputAccessoryViewHeightConstraint;
@property (readonly, nonatomic) NSIndexPath *indexPathOfLastMessage;

@end

@implementation ATMessageCenterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.dataSource = [[ATMessageCenterDataSource alloc] initWithDelegate:self];
	[self.dataSource start];
	
	self.dateFormatter = [[NSDateFormatter alloc] init];
	self.dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMdjm" options:0 locale:[NSLocale currentLocale]];
	
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
		
	[self updateConfirmationView];
	
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

	self.inputAccessoryView.layer.borderColor = [[UIColor colorWithRed:215/255.0f green:219/255.0f blue:223/255.0f alpha:1.0f] CGColor];
	self.inputAccessoryView.layer.borderWidth = 0.5;
	
	self.messageView.text = self.draftMessage ?: @"";
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustInsets:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustInsets:) name:UIKeyboardDidHideNotification object:nil];
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
	
	// Find iOS 8 system-provided height constraint on inputAccessoryView
	for (NSLayoutConstraint *constraint in self.inputAccessoryView.constraints) {
		if (constraint.firstItem == self.inputAccessoryView && constraint.firstAttribute == NSLayoutAttributeHeight) {
			self.inputAccessoryViewHeightConstraint = constraint;
			break;
		}
	}
	
	// Fall back to creating one for iOS 7
	if (self.inputAccessoryViewHeightConstraint == nil) {
		// Remove autoresizing-mask-based constraints
		self.inputAccessoryView.translatesAutoresizingMaskIntoConstraints = NO;
		
		// Replace the autoresizing width constraints with our own
		[self.inputAccessoryView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[view]-(0)-|" options:0 metrics:nil views:@{ @"view": self.inputAccessoryView }]];
	
		// Add a height constraint whose constant we can control
		self.inputAccessoryViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.inputAccessoryView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0];
		[self.inputAccessoryView addConstraint:self.inputAccessoryViewHeightConstraint];
	}
	
	[self resizeTextViewForOrientation:self.interfaceOrientation];

	NSString *message = self.messageView.text;
	if (message && ![message isEqualToString:@""]) {
		[self.messageView becomeFirstResponder];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSString *message = self.messageView.text;
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
		cell.dateLabel.text = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageAtIndexPath:indexPath]];
		
		return cell;
	} else {
		ATMessageCenterReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Reply" forIndexPath:indexPath];

		cell.supportUserImageView.imageURL = [self.dataSource imageURLOfSenderAtIndexPath:indexPath];

		cell.replyLabel.text = [self.dataSource textOfMessageAtIndexPath:indexPath];
		
		NSString *dateString = [self.dateFormatter stringFromDate:[self.dataSource dateOfMessageAtIndexPath:indexPath]];
		NSString *userString = [self.dataSource senderOfMessageAtIndexPath:indexPath];
		cell.dateLabel.text = [NSString stringWithFormat:ATLocalizedString(@"%@ - from %@", @"<date> - from <user>"), dateString, userString];
		
		return cell;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 4.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// iOS 7 requires this and there's no good way to instantiate a cell to sample, so we're hard-coding it for now.
	NSString *labelText = [self.dataSource textOfMessageAtIndexPath:indexPath];
	CGFloat marginsAndStuff = [self.dataSource cellTypeAtIndexPath:indexPath] == ATMessageCenterMessageTypeMessage ? 30.0 : 74.0;

	// Support iOS 6-style table views
	if (![self.tableView respondsToSelector:@selector(estimatedRowHeight)]) {
		marginsAndStuff += 18.0;
	}
	
	CGFloat effectiveLabelWidth = CGRectGetWidth(tableView.bounds) - marginsAndStuff;
	CGFloat dateLabelAndStuff = 37.0;
	
	CGSize labelSize = [labelText sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(effectiveLabelWidth, MAXFLOAT)];
	
	return labelSize.height + dateLabelAndStuff;
}

#pragma mark Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self adjustBrandingVisibility];
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
	
	[self updateConfirmationView];
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
	NSString *message = self.messageView.text;
	
	if (message && ![message isEqualToString:@""]) {
		[[ATBackend sharedBackend] sendTextMessageWithBody:message completion:^(NSString *pendingMessageID) {}];
		
		self.messageView.text = @"";
	}
	
	[self resizeTextViewForOrientation:self.interfaceOrientation];
}

#pragma mark - Private

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

- (void)adjustInsets:(NSNotification *)notification {
	CGRect messageRect = [self.tableView rectForRowAtIndexPath:self.indexPathOfLastMessage];
	
	// Adjust bottom edge inset so that the scroll view will let us scroll last message to top
	UIEdgeInsets edgeInsets = self.tableView.contentInset;
	edgeInsets.bottom =  self.tableView.bounds.size.height - messageRect.size.height - self.confirmationView.bounds.size.height - edgeInsets.top - 16.0;
	self.tableView.contentInset = edgeInsets;
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

- (void)updateConfirmationView {	
	switch (self.dataSource.lastSentMessageState) {
		case ATPendingMessageStateSending:
			switch ([[ATReachability sharedReachability] currentNetworkStatus]) {
				case ATNetworkNotReachable:
					self.confirmationView.confirmationHidden = NO;
					self.confirmationView.confirmationLabel.text = self.interaction.networkErrorTitle;
					self.confirmationView.statusLabel.text = self.interaction.networkErrorMessage;
					break;
					
				default:
#warning DEBUG
					self.confirmationView.confirmationHidden = NO;
					self.confirmationView.confirmationLabel.text = @"Sending...";
					self.confirmationView.statusLabel.text = @"Sending...";
					break;
			}
			break;
			
		case ATPendingMessageStateConfirmed:
			self.confirmationView.confirmationHidden = NO;
			self.confirmationView.confirmationLabel.text = self.interaction.confirmationText;
			self.confirmationView.statusLabel.text = self.interaction.statusText;
			break;
			
		case ATPendingMessageStateError:
			switch ([[ATReachability sharedReachability] currentNetworkStatus]) {
				case ATNetworkNotReachable:
					self.confirmationView.confirmationHidden = NO;
					self.confirmationView.confirmationLabel.text = self.interaction.networkErrorTitle;
					self.confirmationView.statusLabel.text = self.interaction.networkErrorMessage;
					break;
					
				default:
					self.confirmationView.confirmationHidden = NO;
					self.confirmationView.confirmationLabel.text = self.interaction.HTTPErrorTitle;
					self.confirmationView.statusLabel.text = self.interaction.HTTPErrorMessage;
			}
			break;
		
		default:
			self.confirmationView.confirmationHidden = YES;
			break;
	}
}

- (void)resizeTextViewForOrientation:(UIInterfaceOrientation)orientation {
	BOOL isLandscapeOnPhone = UIInterfaceOrientationIsLandscape(orientation) && [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
	
	CGFloat minHeight = isLandscapeOnPhone ? 32 : 44;
	CGFloat maxHeight = isLandscapeOnPhone ? 100 : 200;
	
	CGFloat preferedHeight = [self.messageView.text sizeWithFont:self.messageView.font constrainedToSize:CGSizeMake(CGRectGetWidth(self.messageView.frame), CGFLOAT_MAX)].height;
	preferedHeight += self.messageView.textContainerInset.top + self.messageView.textContainerInset.bottom;
	
	CGFloat textViewHeight = fmax(minHeight, preferedHeight);
	textViewHeight = fmin(textViewHeight, maxHeight);
	
	self.inputAccessoryViewHeightConstraint.constant = textViewHeight;
	
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
	
	CGRect lastMessageFrame = [self.tableView rectForRowAtIndexPath:self.indexPathOfLastMessage];
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

@end
