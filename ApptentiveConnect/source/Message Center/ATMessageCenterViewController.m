//
//  ATMessageCenterViewController.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 9/28/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>

#import "ATMessageCenterViewController.h"
#import "ATBackend.h"
#import "ATConnect.h"
#import "ATData.h"
#import "ATFakeMessage.h"
#import "ATLog.h"
#import "ATMessage.h"
#import "ATMessageSender.h"
#import "ATMessageTask.h"
#import "ATPendingMessage.h"
#import "ATPersonUpdater.h"
#import "ATTaskQueue.h"
#import "ATTextMessage.h"
#import "ATInfoViewController.h"

typedef enum {
	ATMessageCellTypeUnknown,
	ATMessageCellTypeFake,
	ATMessageCellTypeText
} ATMessageCellType;

#define TextViewPadding 2

@interface ATMessageCenterViewController ()
- (void)relayoutSubviews;
- (void)styleTextView;
- (CGRect)formRectToShow;
- (void)registerForKeyboardNotifications;
- (void)keyboardWillBeShown:(NSNotification *)aNotification;
- (void)keyboardWasShown:(NSNotification *)aNotification;
- (void)keyboardWillBeHidden:(NSNotification *)aNotification;
- (NSFetchedResultsController *)fetchedMessagesController;
- (void)scrollToBottomOfTableView;
@end

@implementation ATMessageCenterViewController {
	BOOL firstLoad;
	BOOL attachmentsVisible;
	CGRect currentKeyboardFrameInView;
	CGFloat composerFieldHeight;
	NSFetchedResultsController *fetchedMessagesController;
	ATPendingMessage *composingMessage;
	BOOL animatingTransition;
	NSDateFormatter *messageDateFormatter;
	UIImage *pickedImage;
}
@synthesize tableView, containerView, composerView, composerBackgroundView, attachmentButton, textView, sendButton, attachmentView, fakeCell;
@synthesize userCell, developerCell;

- (id)init {
	self = [super initWithNibName:@"ATMessageCenterViewController" bundle:[ATConnect resourceBundle]];
	if (self != nil) {
	}
	return self;
}

#warning Fixme
- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSUInteger messageCount = [ATData countEntityNamed:@"ATMessage" withPredicate:nil];
	if (messageCount == 0) {
		ATFakeMessage *fakeMessage = (ATFakeMessage *)[ATData newEntityNamed:@"ATFakeMessage"];
		fakeMessage.subject = NSLocalizedString(@"Welcome", @"Welcome");
		fakeMessage.body = ATLocalizedString(@"Use this area to communicate with the developer of this app! If you have questions, suggestions, concerns, or just want to help us make the app better or get in touch, feel free to send us a message!", @"Placeholder welcome message.");
		fakeMessage.creationTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
		fakeMessage.sender = [ATMessageSender newOrExistingMessageSenderFromJSON:@{@"id":@"demodevid"}]; //!! replace
		[fakeMessage release], fakeMessage = nil;
	}
	
	UIImageView *logoView = [[UIImageView alloc] initWithImage:[ATBackend imageNamed:@"at_apptentive_icon_small"]];
	[self.navigationController.navigationBar addSubview:logoView];
	logoView.frame = CGRectMake(60, 12, logoView.bounds.size.width, logoView.bounds.size.height);
	[logoView release], logoView = nil;
	
	messageDateFormatter = [[NSDateFormatter alloc] init];
	messageDateFormatter.dateStyle = NSDateFormatterMediumStyle;
	messageDateFormatter.timeStyle = NSDateFormatterShortStyle;
	[ATTextMessage clearComposingMessages];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
	self.tableView.scrollsToTop = YES;
	firstLoad = YES;
	[self registerForKeyboardNotifications];
	self.title = ATLocalizedString(@"Message Center", @"Message Center title");
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed:)] autorelease];
	[self styleTextView];
	
	self.composerBackgroundView.image = [[ATBackend imageNamed:@"at_inbox_composer_bg"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 0, 29, 19)];
	[self.attachmentButton setImage:[ATBackend imageNamed:@"at_plus_button"] forState:UIControlStateNormal];
	[self.cameraButton setImage:[ATBackend imageNamed:@"at_attachment_photo_icon"] forState:UIControlStateNormal];
	[self.locationButton setImage:[ATBackend imageNamed:@"at_attachment_location"] forState:UIControlStateNormal];
	[self.emailButton setImage:[ATBackend imageNamed:@"at_attachment_email"] forState:UIControlStateNormal];
	[self.iconButton setImage:[ATBackend imageNamed:@"at_apptentive_icon_small"] forState:UIControlStateNormal];
	[self.tableView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dust_bg"]]];
	[self.containerView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dust_bg"]]];
	[self.composerView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_denim_bg"]]];
	[self.attachmentView setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_denim_bg"]]];
	
	[self.view addSubview:self.containerView];
	
	composerFieldHeight = self.textView.frame.size.height;
	
	
	[self.sendButton setBackgroundImage:[ATBackend imageNamed:@"at_send_button_v2_bg"] forState:UIControlStateNormal];
	self.sendButton.layer.cornerRadius = 4;
	self.sendButton.layer.borderColor = [UIColor colorWithRed:63/255. green:63/255. blue:63/255. alpha:1].CGColor;
	self.sendButton.layer.borderWidth = 2;
	[self.sendButton setTitleColor:[UIColor colorWithRed:31/255. green:31/255. blue:31/255. alpha:1] forState:UIControlStateNormal];
	[self.sendButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self.sendButton.titleLabel setShadowOffset:CGSizeMake(0, 1)];
	[self.sendButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.4] forState:UIControlStateDisabled];
	self.sendButton.clipsToBounds = YES;
	
	NSError *error = nil;
	if (![self.fetchedMessagesController performFetch:&error]) {
		NSLog(@"got an error loading messages: %@", error);
		//!! handle me
	}
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
		[self relayoutSubviews];
	});
	
//	[self.navigationController.navigationBar setBackgroundColor:[UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_denim_blue_bg"]]];
	[self.navigationController.navigationBar setBackgroundImage:[ATBackend imageNamed:@"at_toolbar_denim_bg"] forBarMetrics:UIBarMetricsDefault];

}

#warning Implement for iOS 4
- (void)viewDidLayoutSubviews {
	[self relayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[pickedImage release], pickedImage = nil;
	[messageDateFormatter release];
	[tableView release];
	[attachmentView release];
	[containerView release];
	[composerView release];
	[composerBackgroundView release];
	[textView release];
	[sendButton release];
	[attachmentButton release];
	[fetchedMessagesController release], fetchedMessagesController = nil;
	[_cameraButton release];
	[_locationButton release];
	[_emailButton release];
	[_iconButton release];
	[super dealloc];
}

- (void)viewDidUnload {
	[self setTableView:nil];
	[self setAttachmentView:nil];
	[self setContainerView:nil];
	[self setComposerView:nil];
	[self setComposerBackgroundView:nil];
	[self setTextView:nil];
	[self setSendButton:nil];
	[self setAttachmentButton:nil];
	[self setCameraButton:nil];
	[self setLocationButton:nil];
	[self setEmailButton:nil];
	[self setIconButton:nil];
	[super viewDidUnload];
}

- (IBAction)donePressed:(id)sender {
	[self.navigationController.presentingViewController dismissModalViewControllerAnimated:YES];
//	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)sendPressed:(id)sender {
	@synchronized(self) {
		ATPendingMessage *message = nil;
		if (composingMessage) {
			message = composingMessage;
			composingMessage = nil;
		} else {
			message = [[ATPendingMessage alloc] init];
		}
		message.body = [self.textView text];
		
		ATTextMessage *textMessage = [ATTextMessage findMessageWithPendingID:message.pendingMessageID];
		if (!textMessage) {
			textMessage = [ATTextMessage createMessageWithPendingMessage:message];
		}
		textMessage.body = message.body;
		textMessage.pendingState = [NSNumber numberWithInt:ATPendingMessageStateSending];
		[[[ATBackend sharedBackend] managedObjectContext] save:nil];
		
		// Give it a wee bit o' delay.
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{		ATMessageTask *task = [[ATMessageTask alloc] init];
			task.message = message;
			[[ATTaskQueue sharedTaskQueue] addTask:task];
			[[ATTaskQueue sharedTaskQueue] start];
			[task release], task = nil;
		});
		[message release], message = nil;
		self.textView.text = @"";
	}
}

- (IBAction)paperclipPressed:(id)sender {
	attachmentsVisible = !attachmentsVisible;
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		[self.textView resignFirstResponder];
	} else {
		if (!animatingTransition) {
			[UIView animateWithDuration:0.3 animations:^(void){
				animatingTransition = YES;
				[self relayoutSubviews];
			} completion:^(BOOL finished) {
				animatingTransition = NO;
				[self scrollToBottomOfTableView];
			}];
		}
	}
}

- (IBAction)showInfoView:(id)sender {
	ATInfoViewController *vc = [[ATInfoViewController alloc] init];
	[self presentModalViewController:vc animated:YES];
	[vc release], vc = nil;
}

- (IBAction)cameraPressed:(id)sender {
	ATSimpleImageViewController *vc = [[ATSimpleImageViewController alloc] initWithDelegate:self];
	[self presentModalViewController:vc animated:YES];
	[vc release], vc = nil;
}

#pragma mark Private
- (void)relayoutSubviews {
	CGFloat viewHeight = self.view.bounds.size.height;
	
	CGRect composerFrame = composerView.frame;
	CGRect tableFrame = tableView.frame;
	CGRect containerFrame = containerView.frame;
	CGRect attachmentFrame = attachmentView.frame;
	
	composerFrame.size.height = composerFieldHeight + 2*TextViewPadding;
	
	if (!attachmentsVisible) {
		composerFrame.origin.y = viewHeight - composerView.frame.size.height;
	} else {
		composerFrame.origin.y = viewHeight - composerView.frame.size.height - attachmentFrame.size.height;
	}
	
	if (!CGRectEqualToRect(CGRectZero, currentKeyboardFrameInView)) {
		CGFloat bottomOffset = viewHeight - composerFrame.size.height;
		CGFloat keyboardOffset = currentKeyboardFrameInView.origin.y - composerFrame.size.height;
		if (attachmentsVisible) {
			bottomOffset = bottomOffset - attachmentFrame.size.height;
			keyboardOffset = keyboardOffset - attachmentFrame.size.height;
		}
		composerFrame.origin.y = MIN(bottomOffset, keyboardOffset);
	}
	
	tableFrame.origin.y = 0;
	tableFrame.size.height = composerFrame.origin.y;
	containerFrame.size.height = tableFrame.size.height + composerFrame.size.height + attachmentFrame.size.height;
	attachmentFrame.origin.y = composerFrame.origin.y + composerFrame.size.height;
	
	//containerView.frame = containerFrame;
	//[containerView setNeedsLayout];
	tableView.frame = tableFrame;
	composerView.frame = composerFrame;
	attachmentView.frame = attachmentFrame;
	/*
	 if (!CGRectEqualToRect(composerFrame, composerView.frame)) {
	 NSLog(@"composerFrame: %@ != %@", NSStringFromCGRect(composerFrame), NSStringFromCGRect(composerView.frame));
	 }
	 if (!CGRectEqualToRect(attachmentFrame, attachmentView.frame)) {
	 NSLog(@"attachmentFrame: %@ != %@", NSStringFromCGRect(attachmentFrame), NSStringFromCGRect(attachmentView.frame));
	 }
	 if (!CGRectEqualToRect(containerFrame, containerView.frame)) {
	 NSLog(@"containerFrame: %@ != %@", NSStringFromCGRect(containerFrame), NSStringFromCGRect(containerView.frame));
	 }
	 */
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self relayoutSubviews];
	
	CGRect containerFrame = containerView.frame;
	containerFrame.size.height = self.tableView.frame.size.height + self.composerView.frame.size.height + self.attachmentView.frame.size.height;
	containerView.frame = containerFrame;
	[containerView setNeedsLayout];
	[self relayoutSubviews];
}

- (void)styleTextView {
	self.textView.placeholder = ATLocalizedString(@"What's on your mind?", @"Placeholder for message center text input.");
	self.textView.clipsToBounds = YES;
	self.textView.font = [UIFont systemFontOfSize:13];
	self.textView.style = ATResizingTextViewStyleV2;
}


- (NSFetchedResultsController *)fetchedMessagesController {
	if (!fetchedMessagesController) {
		NSFetchRequest *request = [[NSFetchRequest alloc] init];
		[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:[[ATBackend sharedBackend] managedObjectContext]]];
		[request setFetchBatchSize:20];
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationTime" ascending:YES];
		[request setSortDescriptors:@[sortDescriptor]];
		[sortDescriptor release], sortDescriptor = nil;
		
		NSFetchedResultsController *newController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[[ATBackend sharedBackend] managedObjectContext] sectionNameKeyPath:nil cacheName:@"at-messages-cache"];
		newController.delegate = self;
		fetchedMessagesController = newController;
		
		[request release], request = nil;
	}
	return fetchedMessagesController;
}

- (void)scrollToBottomOfTableView {
	id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedMessagesController sections] objectAtIndex:0];
	if ([sectionInfo numberOfObjects] > 0) {
		NSUInteger row = [sectionInfo numberOfObjects] - 1;
		NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
		[self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
	}
}

#pragma mark UITextViewDelegate
- (void)resizingTextView:(ATResizingTextView *)textView willChangeHeight:(CGFloat)height {
	if (composerFieldHeight != height) {
		composerFieldHeight = height;
		//[self viewDidLayoutSubviews];
	}
}

- (void)resizingTextView:(ATResizingTextView *)textView didChangeHeight:(CGFloat)height {
	[self relayoutSubviews];
	[self scrollToBottomOfTableView];
}

- (BOOL)resizingTextViewShouldBeginEditing:(ATResizingTextView *)textView {
	return YES;
}

- (void)resizingTextViewDidChange:(ATResizingTextView *)aTextView {
	if (aTextView.text && ![aTextView.text isEqualToString:@""]) {
		if (!composingMessage) {
			composingMessage = [[ATPendingMessage alloc] init];
		}
		composingMessage.body = aTextView.text;
		if (![ATTextMessage findMessageWithPendingID:composingMessage.pendingMessageID]) {
			[ATTextMessage createMessageWithPendingMessage:composingMessage];
		}
	} else {
		if (composingMessage) {
			ATMessage *message = [ATTextMessage findMessageWithPendingID:composingMessage.pendingMessageID];
			NSManagedObjectContext *context = [[ATBackend sharedBackend] managedObjectContext];
			[context deleteObject:message];
			[composingMessage release], composingMessage = nil;
		}
	}
}

#pragma mark Keyboard Handling
- (CGRect)formRectToShow {
	CGRect result = self.composerView.frame;
	return result;
}

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}


- (void)keyboardWillBeShown:(NSNotification *)aNotification {
	attachmentsVisible = NO;
	NSDictionary *info = [aNotification userInfo];
	CGRect kbFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	CGRect kbAdjustedFrame = [self.view.window convertRect:kbFrame toView:self.view];
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self scrollToBottomOfTableView];
		}];
	} else {
		currentKeyboardFrameInView = CGRectIntersection(self.view.frame, kbAdjustedFrame);
	}
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
	[self scrollToBottomOfTableView];
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
	NSNumber *duration = [[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSNumber *curve = [[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	
	if (!animatingTransition) {
		[UIView animateWithDuration:[duration floatValue] animations:^(void){
			animatingTransition = YES;
			[UIView setAnimationCurve:[curve intValue]];
			currentKeyboardFrameInView = CGRectZero;
			[self relayoutSubviews];
		} completion:^(BOOL finished) {
			animatingTransition = NO;
			[self scrollToBottomOfTableView];
		}];
	} else {
		currentKeyboardFrameInView = CGRectZero;
	}
}

#pragma mark ATSimpleImageViewControllerDelegate
- (void)imageViewController:(ATSimpleImageViewController *)vc pickedImage:(UIImage *)image fromSource:(ATFeedbackImageSource)source {
	if (pickedImage != image) {
		[pickedImage release], pickedImage = nil;
		pickedImage = [image retain];
	}
}

- (void)imageViewControllerWillDismiss:(ATSimpleImageViewController *)vc animated:(BOOL)animated {
	if (pickedImage) {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:ATLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:ATLocalizedString(@"Send Image", @"Send image button title"), nil];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
			[actionSheet showFromRect:sendButton.bounds inView:sendButton animated:YES];
		} else {
			[actionSheet showInView:self.view];
		}
		[actionSheet autorelease];
	}
}

- (ATFeedbackAttachmentOptions)attachmentOptionsForImageViewController:(ATSimpleImageViewController *)vc {
	return ATFeedbackAllowPhotoAttachment & ATFeedbackAllowTakePhotoAttachment;
}

- (UIImage *)defaultImageForImageViewController:(ATSimpleImageViewController *)vc {
	return pickedImage;
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		ATLogDebug(@"picked button 0");
	} else if (buttonIndex == 1) {
		[pickedImage release], pickedImage = nil;
	}
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
	if (pickedImage) {
		[pickedImage release], pickedImage = nil;
	}
}

#pragma mark UIScrollViewDelegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
	return YES;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	ATTextMessageUserCell *cell = (ATTextMessageUserCell *)[self tableView:aTableView cellForRowAtIndexPath:indexPath];
	return [cell cellHeightForWidth:aTableView.bounds.size.width];
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (firstLoad && indexPath.row == 0 && indexPath.section == 0) {
		firstLoad = NO;
		[self scrollToBottomOfTableView];
	}
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedMessagesController sections] objectAtIndex:0];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *FakeCellIdentifier = @"ATFakeMessageCell";
	static NSString *UserCellIdentifier = @"ATTextMessageUserCell";
	static NSString *DevCellIdentifier = @"ATTextMessageDevCell";
	
	ATMessageCellType cellType = ATMessageCellTypeUnknown;
	
	UITableViewCell *cell = nil;
	ATMessage *message = (ATMessage *)[fetchedMessagesController objectAtIndexPath:indexPath];
	
	if ([message isKindOfClass:[ATFakeMessage class]]) {
		cellType = ATMessageCellTypeFake;
	} else if ([message isKindOfClass:[ATTextMessage class]]) {
		cellType = ATMessageCellTypeText;
	}
	
	BOOL showDate = NO;
	NSString *dateString = nil;
	
	if (indexPath.row == 0) {
		showDate = YES;
	} else {
		ATMessage *previousMessage = (ATMessage *)[fetchedMessagesController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section]];
		if ([message.creationTime doubleValue] - [previousMessage.creationTime doubleValue] > 60 * 5) {
			showDate = YES;
		}
	}
	
	
	if (showDate) {
		NSTimeInterval t = (NSTimeInterval)[message.creationTime doubleValue];
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:t];
		dateString = [messageDateFormatter stringFromDate:date];
	}
	
	if (cellType == ATMessageCellTypeText) {
		ATTextMessageUserCell *textCell = nil;
		ATPerson *person = [ATPersonUpdater currentPerson];
		ATTextMessageCellType cellSubType = (person != nil && [person.apptentiveID isEqualToString:message.sender.apptentiveID]) ? ATTextMessageCellTypeUser : ATTextMessageCellTypeDeveloper;
		if (person == nil) {
			if ([@"demouserid" isEqualToString:message.sender.apptentiveID] || [[message pendingState] intValue] == ATPendingMessageStateComposing || [[message pendingState] intValue] == ATPendingMessageStateSending) {
				cellSubType = ATTextMessageCellTypeUser;
			} else {
				cellSubType = ATTextMessageCellTypeDeveloper;
			}
		}
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
				textCell.messageBubbleImage.image = [[ATBackend imageNamed:@"at_chat_bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 27, 21)];
				textCell.userIcon.image = [ATBackend imageNamed:@"profile-photo"];
			} else {
				textCell = developerCell;
				textCell.messageBubbleImage.image = [[ATBackend imageNamed:@"at_urbanspoon_chat_bubble"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 21, 27, 15)];
				textCell.userIcon.image = [UIImage imageNamed:@"dev_photo"];
			}
			[[textCell retain] autorelease];
			[userCell release], userCell = nil;
			[developerCell release], developerCell = nil;
			textCell.selectionStyle = UITableViewCellSelectionStyleNone;
			textCell.userIcon.layer.cornerRadius = 4.0;
			textCell.userIcon.layer.masksToBounds = YES;
			
			textCell.composingBubble.image = [ATBackend imageNamed:@"at_composing_bubble"];
			UIView *backgroundView = [[UIView alloc] init];
			backgroundView.backgroundColor = [UIColor colorWithPatternImage:[ATBackend imageNamed:@"at_dust_bg"]];
			textCell.backgroundView = backgroundView;
			[backgroundView release];
			textCell.messageText.dataDetectorTypes = UIDataDetectorTypeAll;
		}
		textCell.composing = NO;
		if ([message isKindOfClass:[ATTextMessage class]]) {
			NSString *messageBody = [(ATTextMessage *)message body];
			textCell.messageText.text = messageBody;
			if ([[message pendingState] intValue] == ATPendingMessageStateSending) {
				NSAttributedString *sending = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", NSLocalizedString(@"Sending:", @"Sending prefix on messages that are sending")] attributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:15]}];
				
				NSAttributedString *messageText = [[NSAttributedString alloc] initWithString:messageBody attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15]}];
				NSMutableAttributedString *sFinal = [[NSMutableAttributedString alloc] initWithAttributedString:sending];
				[sFinal appendAttributedString:messageText];
				
				textCell.messageText.attributedText = sFinal;
				[messageText release], messageText = nil;
				[sending release], sending = nil;
				[sFinal release], sFinal = nil;
			} else if ([[message pendingState] intValue] == ATPendingMessageStateComposing) {
				textCell.composing = YES;
				textCell.textLabel.text = @"";
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
		
		cell = textCell;
	} else if (cellType == ATMessageCellTypeFake) {
		ATFakeMessageCell *currentCell = (ATFakeMessageCell *)[tableView dequeueReusableCellWithIdentifier:FakeCellIdentifier];
		
		if (!currentCell) {
			UINib *nib = [UINib nibWithNibName:@"ATFakeMessageCell" bundle:[ATConnect resourceBundle]];
			[nib instantiateWithOwner:self options:nil];
			currentCell = fakeCell;
			[[currentCell retain] autorelease];
			[fakeCell release], fakeCell = nil;
			
			currentCell.selectionStyle = UITableViewCellSelectionStyleNone;
			currentCell.messageText.dataDetectorTypes = UIDataDetectorTypeAll;
		}
		if ([message isKindOfClass:[ATFakeMessage class]]) {
			ATFakeMessage *fakeMessage = (ATFakeMessage *)message;
			NSString *messageSubject = fakeMessage.subject;
			NSString *messageBody = fakeMessage.body;
			
			NSMutableParagraphStyle *centerParagraphStyle = [[NSMutableParagraphStyle alloc] init];
			[centerParagraphStyle setAlignment:UITextAlignmentCenter];
			NSAttributedString *boldSubject = [[NSAttributedString alloc] initWithString:messageSubject attributes:@{NSFontAttributeName : [UIFont fontWithName:@"AmericanTypewriter-Bold" size:15], NSParagraphStyleAttributeName:centerParagraphStyle}];
			currentCell.subjectText.attributedText = boldSubject;
			[boldSubject release], boldSubject = nil;
			[centerParagraphStyle release], centerParagraphStyle = nil;
			
			currentCell.messageText.text = messageBody;
		}
		
		if (showDate) {
			currentCell.dateLabel.text = dateString;
			currentCell.showDateLabel = YES;
		} else {
			currentCell.showDateLabel = NO;
		}
		
		cell = currentCell;
	}
	return cell;
}

#pragma mark NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	[tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[tableView endUpdates];
	[self scrollToBottomOfTableView];
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
